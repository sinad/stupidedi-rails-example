# Parses an SH856 (Advance Ship Notice ASN) EDI message
class Edi::AdvanceShipNotice
  attr_reader :config

  def initialize
    @config = configuration
  end

  # Parse the EDI message and return a machine for navigation
  def parse(s)
    parser = Stupidedi::Builder::StateMachine.build(@config)
    machine, result = parser.read(Stupidedi::Reader.build(s))

    # Report fatal tokenizer failures
    if result.fatal?
      result.explain{ |reason| raise reason + " at #{result.position.inspect}" }
    end
    machine
  end

  # Navigate the parsed document and select few interesting segment-element values to be returned as a hash
  def self.to_hash(machine)
    result = []
    machine.first.map do |isa|
      isa.iterate(:GS) do |gs|
        gs.iterate(:ST) do |st|
          result << order = {}
          
          st.find(:BSN).tap do |bsn|
            bsn.element(2).tap { |x| order[:shipment_identification] = x.node.to_s }
            bsn.element(3).tap { |x| order[:date] = x.node.to_s }
          end
          
          st.find(:DTM).tap do |dtm|
            dtm.element(2).tap { |x| order[:date_reference] = x.node.to_s }
          end

          st.iterate(:HL, nil, nil, 'S') do |hl_shipment|
            hl_shipment.find(:TD5).tap do |td5|
              td5.element(3).tap { |x| order[:carrier] = x.node.to_s }
            end
            hl_shipment.find(:REF).tap do |ref|
              ref.element(2).tap { |x| order[:order_reference] = x.node.to_s }
            end

            parent = nil
            hl_shipment.element(1).tap { |x| parent = x.node.to_s }

            st.iterate(:HL) do |hl_item|
              line_item = false
              hl_item.element(3).tap { |x| line_item = x.node.to_s == 'I' }
              next unless line_item

              (order[:line_items] ||= []) << line_item = {}
              hl_item.find(:LIN).tap do |lin|
                lin.element(1).tap { |x| line_item[:id] = x.node.to_s }
                lin.element(3).tap { |x| line_item[:product_id] = x.node.to_s }
              end
              hl_item.find(:PRF).tap do |prf|
                prf.element(1).tap { |x| line_item[:purchase_order] = x.node.to_s }
              end
              hl_item.find(:SN1).tap do |sn1|
                sn1.element(2).tap { |x| line_item[:quantity] = x.node.to_s }
              end
              hl_item.find(:REF).tap do |ref|
                ref.element(2).tap { |x| line_item[:tracking_number] = x.node.to_s }
              end
            end
          end
        end
      end
    end

    result
end

  private

  # Use a subset of the EDI parser only for ASN
  def configuration
    Stupidedi::Config.new.customize do |c|
      c.interchange.customize do |x|
        x.register("00401") { Stupidedi::Versions::Interchanges::FourOhOne::InterchangeDef }
      end

      c.functional_group.customize do |x|
        x.register("004010") { Stupidedi::Versions::FunctionalGroups::FortyTen::FunctionalGroupDef }
      end

      c.transaction_set.customize do |x|
        # Not using the barebone transaction set definition, as it doesn't have enough constraints to parse
        # the document with multiple levels of HL (not deterministic)
        # x.register("004010", "SH", "856") { Stupidedi::Contrib::FortyTen::TransactionSetDefs::SH856 }
        
        # Modified the guide to include REF element for the Line Item HL
        x.register("004010", "SH", "856") { Stupidedi::Contrib::FortyTen::Guides::SH856  }
      end
    end
  end

end
