ruleset wovyn_base {
  meta {
    use module keyModule
    use module twilioModule alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
    shares __testing, temperature_shreshold, SMS_number
  }

  global {
    temperature_threshold = 40
    SMS_number = "+13185370837"

    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                              "attrs": [ "emitterGUID", "eventDomain", "eventName", "genericThing", "property", "specificThing" ] } ] }
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat where event:attr("genericThing")
    pre {
      attributes = event:attrs.klog("attrs");
    }
    every {
      send_directive("say", {"something":"Heartbeat received"});
    }
    always {
      raise wovyn event "new_temperature_reading" attributes {
        "temperature" : event:attr("genericThing"){["data", "temperature"]},
        "timestamp" : time:now()
      }
    }
  }

  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      attributes = event:attrs.klog("attributes are ");
      temperatureF = event:attr("temperature")[0]{"temperatureF"}.klog("temperatureF is ");
      temperatureThreshold = temperature_threshold.klog("temperature_threshold is ");
      isHotter = (temperatureF > temperature_threshold) => "yes" | "no";
      tooHot = (temperatureF > temperature_threshold);
    }
    every {
      send_directive("say", {"Was there a temperature violation?": isHotter});
    }
    always {
      raise wovyn event "threshold_violation" attributes event:attrs if tooHot;
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
    twilio:send_sms(SMS_number,
                    "+12016854216",
                    "There was a threshold violation."
                   )
  }

}