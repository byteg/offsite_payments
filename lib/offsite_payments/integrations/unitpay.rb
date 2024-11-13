module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    # Documentation:
    # https://help.unitpay.ru/
    module Unitpay
      module Common
        def pay?
          "pay" == method_name
        end

        def generate_signature_string
          params_string = params.except("sign", "signature").keys.sort.collect {|k| params[k] }.join '{up}'
          "#{method_name}{up}#{params_string}{up}#{secret}"
        end

        def generate_signature
          Digest::SHA256.hexdigest(generate_signature_string)
        end
      end

      class Notification < OffsitePayments::Notification
        include Common
        attr_accessor :method_name

        def parse(input_params)
          @params = input_params["params"] || {}
          @method_name = input_params["method"]
        end

        def recognizes?
          params.has_key?('account')
        end

        def amount
          amount_in_string = params['payerSum']
          BigDecimal(amount_in_string)
        end

        def key_present?
          params["signature"].present?
        end

        def item_id
          params['account']
        end

        def payment_id
          params['unitpayId']
        end

        def gross
          params['profit']
        end

        def security_key
          params["signature"]
        end

        def secret
          @options[:secret]
        end

        def acknowledge(authcode = nil)
          (security_key == generate_signature)
        end

        def success_response
          pay? ? success_pay_response : success_check_response
        end

        def fail_response
          pay? ? fail_pay_response : fail_check_response
        end

        def success_check_response(*args)
          {
            result: {
              message: "Запрос успешно обработан"
            }
          }.to_json
        end

        def success_pay_response(*args)
          {
            result: {
              message: "Запрос успешно обработан"
            }
          }.to_json
        end

        def fail_check_response(msg = "Произошла ошибка")
          {
            error: {
              message: msg
            }
          }.to_json
        end

        def fail_pay_response(msg = "Произошла ошибка")
          {
            error: {
              message: msg
            }
          }.to_json
        end
      end

    end
  end
end
