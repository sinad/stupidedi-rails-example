class AdvanceShipNoticeController < ApplicationController
  def receive
    logger.debug "*** Received EDI message ***"
    
    processor = Edi::AdvanceShipNotice.new
    begin
      # split message in case multiple ISA segments are present
      @orders = []
      request.raw_post.scan(/^ISA\*.*?IEA.*?\~/m) do |chunk|
        logger.debug "*** Parsing message ***"
        logger.debug '=' * 80
        logger.debug chunk
        logger.debug '=' * 80
        machine = processor.parse(chunk)
        @orders += Edi::AdvanceShipNotice.to_hash(machine)
      end
    rescue Exception => e
      logger.error("EDI parsing error: #{e.message}")
      return head(:bad_request, :error => e.message)
    end

    logger.debug @orders

    head :ok
  end
end
