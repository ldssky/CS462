ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    logging on
    shares hello, __testing, monkey
  }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }

    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
                               { "name": "__testing" } ],
                  "events": [ { "domain": "echo", "type": "hello",
                                "attrs": [ "name" ] },
                              { "domain": "echo", "type": "monkey",
                                "attrs": [ "name" ] },
                              { "domain": "echo", "type": "monkey" } ]
                }
  }
  
  rule hello_world {
    select when echo hello
    pre {
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("say", {"something":"Hello " + name})
  }

  rule hello_monkey {
    select when echo monkey
    pre {
      name = event:attr("name").defaultsTo("Monkey").klog("our name: ")
    }
    send_directive("say", {"something":"Hello " + name})
  }
  
}