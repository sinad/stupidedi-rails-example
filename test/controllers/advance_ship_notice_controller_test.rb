require 'test_helper'

class AdvanceShipNoticeControllerTest < ActionController::TestCase
  test "parses ASN EDI message with one order having one line item" do
    post :receive, read_fixture('sh856-1.edi')

    assert_response :success
    orders = assigns["orders"]
    assert_not_nil orders
    assert_equal 1, orders.length
    order = orders[0]
    assert_equal '478157', order[:shipment_identification]
    assert_equal '2014-10-01', order[:date]
    assert_equal 'FDEP', order[:carrier]
    assert_equal '1412105525', order[:order_reference]
    assert_not_nil order[:line_items]
    assert_equal 1, order[:line_items].length
    assert_equal 'testwaybill95642634', order[:line_items][0][:tracking_number]
  end

  test "parses ASN EDI message with one order having two line items" do
    post :receive, read_fixture('sh856-2.edi')

    assert_response :success
    orders = assigns["orders"]
    assert_not_nil orders
    assert_equal 1, orders.length
    order = orders[0]
    assert_equal '478158', order[:shipment_identification]
    assert_equal '2014-10-01', order[:date]
    assert_equal 'FDEP', order[:carrier]
    assert_equal '1412105559', order[:order_reference]
    assert_not_nil order[:line_items]
    assert_equal 2, order[:line_items].length
    assert_equal 'TESTwaybill95642633', order[:line_items][0][:tracking_number]
    assert_equal 'TESTwaybill95642633', order[:line_items][1][:tracking_number]
  end

  test "parses ASN EDI message with combined orders" do
    post :receive, read_fixture('sh856-3.edi')

    assert_response :success
    orders = assigns["orders"]
    assert_not_nil orders
    assert_equal 2, orders.length

    order = orders[0]
    assert_equal '478157', order[:shipment_identification]
    assert_equal '2014-10-01', order[:date]
    assert_equal 'FDEP', order[:carrier]
    assert_equal '1412105525', order[:order_reference]
    assert_not_nil order[:line_items]
    assert_equal 1, order[:line_items].length
    assert_equal 'testwaybill95642634', order[:line_items][0][:tracking_number]

    order = orders[1]
    assert_equal '478158', order[:shipment_identification]
    assert_equal '2014-10-01', order[:date]
    assert_equal 'FDEP', order[:carrier]
    assert_equal '1412105559', order[:order_reference]
    assert_not_nil order[:line_items]
    assert_equal 2, order[:line_items].length
    assert_equal 'TESTwaybill95642633', order[:line_items][0][:tracking_number]
    assert_equal 'TESTwaybill95642633', order[:line_items][1][:tracking_number]
  end

  private
  def read_fixture(filename)
    result = ""
    File.open(File.join(Rails.root, 'test', 'fixtures', filename)) do |io|
      result = io.read
    end
    result
  end
end
