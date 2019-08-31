ruleset sensor_profile {
  meta {
    provides
        get_all
    shares get_all, __testing
  }

  global {
    get_all = function() {
      json = {"new_sensor_name" : ent:new_sensor_name.defaultsTo("Wovyn_2BD537"), "new_location" : ent:new_location.defaultsTo("Timbuktu"), "new_send_to" : ent:new_send_to.defaultsTo("13185370837"), "new_threshold" : ent:new_threshold.defaultsTo(29)};
      json
    }

    __testing = { "queries": [ { "name": "get_all" },
                               { "name": "__testing" } ],
                  "events": [ { "domain": "sensor", "type": "profile_updated" } ] }
  }

  rule acceptSensorSubscriptions {
    select when wrangler inbound_pending_subscription_added
    always {
      raise wrangler event "pending_subscription_approval" attributes event:attrs;
    }
  }

  rule update_profile {
    select when sensor profile_updated
      pre {
        eventAttrs = event:attrs.klog("event attrs is ");
        name = event:attr("new_sensor_name").defaultsTo(ent:new_sensor_name).klog("name is ");
        location = event:attr("new_location").defaultsTo(ent:new_location).klog("location is ");
        contact = event:attr("new_send_to").defaultsTo(ent:new_send_to).klog("contact is ");
        threshold = event:attr("new_threshold").defaultsTo(ent:new_threshold).klog("threshold is ");
      }
      send_directive("update_profile", {"profile":"updated"});
      always {
        ent:new_sensor_name := name;
        ent:new_location := location;
        ent:new_send_to := contact;
        ent:new_threshold := threshold
      }
  }

}