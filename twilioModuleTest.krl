ruleset twilioModuleTest {
  meta {
    use module keyModule
    use module twilioModule alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
    shares __testing, test_messages
  }

  global {
    test_messages = function(to, from, pageSize) {
      twilio:messages(to, from, pageSize)
    }

    __testing = { "queries": [ { "name": "test_messages", "args": [ "to", "from", "pageSize" ] } ],
                  "events": [ { "domain": "test", "type": "new_message",
                                "attrs": [ "to", "from", "message" ] } ]
                }
  }
 
  rule test_send_sms {
    select when test new_message
    twilio:send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }
}