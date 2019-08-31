ruleset manager_profile {
  meta {
    use module keyModule
    use module twilioModule alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
    use module sensor_profile alias profile
    provides
        get_SMS_number, test_messages, get_notification_number
    shares __testing, get_SMS_number, test_messages, get_notification_number
  }

  global {

    test_messages = function(to, from, pageSize) {
      twilio:messages(to, from, pageSize)
    }

    get_SMS_number = function () {
      "+" + profile:get_all(){"new_send_to"}.klog("SMS number is ")
    }

    get_notification_number = function () {
      notificationNumber = "+12016854216";
      notificationNumber
    }

    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "get_SMS_number" },
                               { "name": "get_notification_number" },
                               { "name": "test_messages", "args": [ "to", "from", "pageSize" ] } ],
                  "events": [ { "domain": "send", "type": "SMS",
                                "attrs": [ "message" ] } ] }
  }

  rule send_SMS {
    select when send SMS
    pre {
      message = event:attr("message")
    }
    twilio:send_sms(get_SMS_number(),
                    get_notification_number(),
                    message
                   )
  }

  rule send_threshold_violation_SMS {
    select when wovyn threshold_violation
    always {
      raise send event "SMS" attributes {
        "message" : "One of the sensors had a threshold violation."
      }
    }
  }

}