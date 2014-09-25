//= require jquery.ui.autocomplete.js
//= require jquery.ui.autocomplete.html.js
//= require hampshire.address_autocomplete.js
//= require hampshire.geolocation.js

$("#menu .toggle").click(function(){
  $("#menu ul").slideToggle("fast", function(){
    $("#menu ul").toggleClass("hidden").css("display", "");
  });
});