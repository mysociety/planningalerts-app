//= require jquery.ui.autocomplete.js
//= require jquery.ui.autocomplete.html.js
//= require select2
//= require underscore
//= require oms.min.js
//= require hampshire.address_autocomplete.js
//= require hampshire.geolocation.js

(function($){
  $("#menu .toggle").click(function(){
    $("#menu ul").slideToggle("fast", function(){
      $("#menu ul").toggleClass("hidden").css("display", "");
    });
  });
  $('.modify-search').click(function(e){
    e.preventDefault();
    if($('#searchbar').is('.shown')){
      var mapTop = $('#sidebar').outerHeight();
    } else {
      var mapTop = $('#searchbar').outerHeight() + $('#sidebar').outerHeight();
    }
    $('#searchbar').slideToggle('fast', function(){
      $('#searchbar').toggleClass('shown').css('display', '');
    });
    $('#map').animate({
      top: mapTop
    }, 'fast');
  });
})(window.jQuery);
