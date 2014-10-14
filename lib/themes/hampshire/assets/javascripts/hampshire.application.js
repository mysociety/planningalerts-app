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

  $(function() {
    var data = [
      {id: 'anything', text: 'Anything'},
      {id: 'conservatories', text: 'Conservatories'},
      {id: 'extensions', text: 'Extensions'},
      {id: 'loft conversions', text: 'Loft Conversions'},
      {id: 'garage conversions', text: 'Garage Conversions'},
      {id: 'doors and windows', text: 'Doors and Windows'},
      {id: 'fences, gates and garden walls', text: 'Fences, Gates and Garden Walls'},
      {id: 'outbuildings', text: 'Outbuildings'},
      {id: 'trees and hedges', text: 'Trees and Hedges'},
      {id: 'major developments', text: 'Major Developments'}
    ];
    var $search = $('#search');
    var existingSearch = $search.val();
    if(existingSearch !== '' && existingSearch !== 'anything') {
      data.unshift({id: existingSearch, text: existingSearch});
    }
    $search.select2({
      width: '75%',
      data: data,
      createSearchChoice: function(term) {
        if($(data).filter(function () { return this.text.localeCompare(term) === 0; }).length === 0) {
          return {id: term, text: 'Search for: "' + term + '"'};
        }
      },
      createSearchChoicePosition: 'top'
    });
  });
})(window.jQuery);