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

    })
    .fail(function(error){
      console.error("Error retrieving current eci: ", error);
    });
  };//end retrieveCurrentEci

  var retrieveCurrentTemp = function(){
    $.ajax({
      url: buildQueryURL(config.default_eci, config.temp_store_rid, config.temperature_func),
      dataType: "json",
      success: function(json){

        //HINT $("#currentTemp") GRABS the html tag with id "currentTemp", and may be changed with the .html function. See the JQuery docs for more info
        console.log("Retrieved Current Temperature: ", json);
        let temp = 0;
        if (json.length > 0) {
          temp = json[json.length-1].temperature;
        }

        $('#currentTemp').html(`<p>${temp}</p>`);

      },
      error: function(error){
        console.error("Error retrieving current temperature: ", error);
      }
    });
  };//end retrieveCurrentTemp

  var setViolationLogs = function(){
    $.ajax({
      url: buildQueryURL(config.default_eci, config.temp_store_rid, config.violation_func),
      dataType: "json",
      success: function(json){

        //HINT $("#violationLogs") GRABS the html tag with id "violationLogs", and may be changed with the .html function. See the JQuery docs for more info
        console.log("Retrieved violation logs: ", json);
        let violationTemps = "";
        $.each(json, function(index, obj){
          $.each(obj, function(key, value){
            $('#violationLogs').append(`<p>${value}</p>`);
          })
        });

      },
      error: function(error){
        console.error("Error retrieving violation logs: ", error);
      }
    });
  };//end violationLogs



  /******************************* END FUNCTION DECLARATIONS ******************************************************
  *****************************************************************************************************************/




  //load initial data
  retrieveCurrentEci();
  retrieveCurrentTemp();
  setViolationLogs();

  //BEGIN BUTTON SETUP
  $('#tempRefresh').click(function(e){
    e.preventDefault();
    retrieveCurrentEci();
    retrieveCurrentTemp();
  });

  //END BUTTON SETUP


});
