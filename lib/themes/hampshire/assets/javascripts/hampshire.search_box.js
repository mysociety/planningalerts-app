(function(_, $, PlanningAlerts){
  $(function() {
    var categories = [{id: 'Anything', text: 'Anything'}];
    var $search = $('#search');
    var existingSearch = $search.val();
    $.each(PlanningAlerts.search.categories, function(index, category) {
      categories.push({id: category, text: category});
    });
    if(existingSearch !== '' && !_.contains(PlanningAlerts.search.categories, existingSearch) && existingSearch !== 'Anything') {
      categories.unshift({id: existingSearch, text: existingSearch});
    }
    $search.select2({
      width: 'element',
      data: categories,
      createSearchChoice: function(term) {
        if($(categories).filter(function () { return this.text.localeCompare(term) === 0; }).length === 0) {
          return {id: term, text: term};
        }
      },
      createSearchChoicePosition: 'top'
    }).on('focus', function() {
      $(this).select2('open');
    });

    $('#status').select2({
      width: 'element',
      minimumResultsForSearch: -1
    }).on('focus', function() {
      $(this).select2('open');
    });
  });
})(window._, window.jQuery, window.PlanningAlerts);