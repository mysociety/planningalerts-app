//= require jquery.ui.autocomplete.js
//= require jquery.ui.autocomplete.html.js
//= require select2
//= require underscore
//= require hampshire.address_autocomplete.js
//= require hampshire.geolocation.js

(function($){
  $("#menu .toggle").click(function(){
    $("#menu ul").slideToggle("fast", function(){
      $("#menu ul").toggleClass("hidden").css("display", "");
    });
  });
})(window.jQuery);
