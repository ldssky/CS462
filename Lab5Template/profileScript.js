$(document).ready(function(){
  /*********************************** HELPER FUNCTIONS ********************************************************
  **************************************************************************************************************/

  //params is a map
  var addParams = function(baseURL, params){
    if(!params){
      return baseURL;
    }

    var url = baseURL + '?';
    $.each(params, function(key, value){
      url += `&${key}=${value}`
    });

    return url;
  }

  //attrs is a map
  var buildEventURL = function(eci, eid, domain, type, attrs){
    var baseURL =  `${config.protocol}${config.server_host}/sky/event/${eci}/${eid}/${domain}/${type}`;
    return addParams(baseURL, attrs)
  }

  //params is a map
  var buildQueryURL = function(eci, rid, funcName, params){
    var baseURL =  `${config.protocol}${config.server_host}/sky/cloud/${eci}/${rid}/${funcName}`;
    return addParams(baseURL, params);
  }

  /******************************* END HELPER FUNCTIONS ***********************************************************
  *****************************************************************************************************************/


  /*********************************** FUNCTION DECLARATIONS ******************************************************
  *****************************************************************************************************************/

  var retrieveChildren = function() {
    $.ajax({
      async: false,
      url: buildQueryURL(config.default_eci, "manage_sensors", "showChildren"),
      dataType: "json"
    })
    .done(function(json){

      console.log("showing children: ", json);

    })
    .fail(function(error){
      console.error("Error retrieving children: ", error);
    });
  };

  var addSensor = function(attrs) {
    let url = buildEventURL(config.default_eci, "manage_sensors", "sensor", "new_sensor", attrs);
    console.log("url:",url);
    $.ajax({
      async: false,
      url: url,
      dataType: "json"
    })
    .done(function(json){

      console.log("adding sensor: ", attrs);
      console.log("sending directive: ", json);

    })
    .fail(function(error){
      console.error("Error adding sensor: ", error);
    });
  };

  var removeSensor = function(attrs) {
    let url = buildEventURL(config.default_eci, "manage_sensors", "sensor", "unneeded_sensor", attrs);
    console.log("url:",url);
    $.ajax({
      async: false,
      url: url,
      dataType: "json"
    })
    .done(function(json){

      console.log("removing sensor: ", attrs);
      console.log("sending directive: ", json);

    })
    .fail(function(error){
      console.error("Error removing sensor: ", error);
    });
  };

  var retrieveCurrentEci = function() {
    $.ajax({
      async: false,
      url: buildQueryURL(config.default_eci, config.eci_store_rid, config.eci_func),
      dataType: "json"
    })
    .done(function(json){

      console.log("Retrieved Current Eci: ", json);
      let currentEci = json[json.length-1].eci;

      config.default_eci = currentEci;
      console.log("config.default_eci is now ", config.default_eci);
      updateData();

    })
    .fail(function(error){
      console.error("Error retrieving current eci: ", error);
    });
  };//end retrieveCurrentEci

  var updateData = function(){
    $.ajax({
      async: false,
      url: buildQueryURL(config.default_eci, config.profile_rid, config.profile_func),
      dataType: 'json'
    })
    .done(function(json){
        
      console.log("Retrieved profile data!", json);
      let name = json["new_sensor_name"];
      let location = json["new_location"];
      let contact = json["new_send_to"];
      let threshold = json["new_threshold"];
      $('#name').html(`<p>${name}</p>`);
      $('#location').html(`<p>${location}</p>`);
      $('#contact').html(`<p>${contact}</p>`);
      $('#threshold').html(`<p>${threshold}</p>`);

    })
    .fail(function(error){
      console.error(error);
    });
  };

  var changeData = function(attrs){
    let url = buildEventURL(config.default_eci, "changeData", "sensor", "profile_updated", attrs);
    console.log("url:",url);
    $.ajax({
      async: false,
      url: url,
      dataType: 'json'
    })
    .done(function(json){
      console.log(json);
      updateData();
    })
    .fail(function(error){
      console.error(error);
    });
  };

  var sendHeartbeat = function(attrs){
    let url = buildEventURL(config.default_eci, "wovyn_base", "wovyn", "heartbeat", attrs);
    console.log("url:", url);
    $.ajax({
      async: false,
      url: url,
      type: "POST",
      data: JSON.stringify(attrs),
      contentType: "application/json"
    })
    .done(function(json){
      console.log(json);
      updateData();
    })
    .fail(function(error){
      console.error(error);
    });
  };

  var testSensors = function(){
    //test adding/removing sensors and setting sensor profile
    addSensor({"sensor_name": "dog"});
    addSensor({"sensor_name": "cat"});
    addSensor({"sensor_name": "horse"});
    retrieveChildren();
    removeSensor({"sensor_name": "cat"});
    retrieveChildren();
    retrieveCurrentEci(); //also calls updateData() to update data from sensor profile

    //test sensors by ensuring they respond correctly to new temperature events and test setting sensor profile
    sendHeartbeat(
      {
          "emitterGUID":"5CCF7F2BD537",
          "eventDomain":"wovyn.emitter",
          "eventName":"sensorHeartbeat",
          "genericThing":{
              "typeId":"2.1.2",
              "typeName":"generic.simple.temperature",
              "healthPercent":56.89,
              "heartbeatSeconds":10,
              "data":{
                  "temperature":[
                      {
                          "name":"ambient temperature",
                          "transducerGUID":"28E3A5680900008D",
                          "units":"degrees",
                          "temperatureF":60,
                          "temperatureC":24.06
                      }
                  ]
              }
          },
          "property":{
              "name":"Wovyn_2BD537",
              "description":"Temp1000",
              "location":{
                  "description":"Timbuktu",
                  "imageURL":"http://www.wovyn.com/assets/img/wovyn-logo-small.png",
                  "latitude":"16.77078",
                  "longitude":"-3.00819"
              }
          },
          "specificThing":{
              "make":"Wovyn ESProto",
              "model":"Temp1000",
              "typeId":"1.1.2.2.1000",
              "typeName":"enterprise.wovyn.esproto.wtemp.1000",
              "thingGUID":"5CCF7F2BD537.1",
              "firmwareVersion":"Wovyn-WTEMP1000-1.14",
              "transducer":[
                  {
                      "name":"Maxim DS18B20 Digital Thermometer",
                      "transducerGUID":"28E3A5680900008D",
                      "transducerType":"Maxim Integrated.DS18B20",
                      "units":"degrees",
                      "temperatureC":24.06
                  }
              ],
              "battery":{
                  "maximumVoltage":3.6,
                  "minimumVoltage":2.7,
                  "currentVoltage":3.21
              }
          },
          "version":2
      }      
    );

  };

  /******************************* END FUNCTION DECLARATIONS ******************************************************
  *****************************************************************************************************************/

  //run on load functions
  retrieveCurrentEci(); //also calls updateData() to update data from sensor profile
  testSensors();

  //set up buttons
  $('#setName').click(function(e){
    e.preventDefault();
    changeData({
      "new_sensor_name": $('#newName').val()
    });
  });

  $('#setLocation').click(function(e){
    e.preventDefault();
    console.log($('#newlocation').val());
    changeData({
      "new_location": $('#newlocation').val()
    });
  });

  $('#setContact').click(function(e){
    e.preventDefault();
    console.log($('#newContact').val());
    changeData({
      "new_send_to": $('#newContact').val()
    });
  });

  $('#setThreshold').click(function(e){
    e.preventDefault();
    changeData({
      "new_threshold": $('#newThreshold').val()
    });
  });
});
