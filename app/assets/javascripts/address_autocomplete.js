var service = new google.maps.places.AutocompleteService();

$("#alert_address,#q").autocomplete({
    html: true,
    source: function(request, response) {
        service.getPlacePredictions({
            input: request.term,
            componentRestrictions: {country: "gb"},
            types: ["geocode"]
        }, function(predictions, status){
            response($.map(predictions, function(prediction){
                // Just highlight the first matched substring
                var length = prediction.matched_substrings[0].length;
                var offset = prediction.matched_substrings[0].offset;
                // Remove the country name from the list to make a slightly shorter version of the text
                textArray = $.map(prediction.terms.slice(0,-1), function(term){
                    return(term.value);
                });
                text = textArray.join(", ")
                var html = text.slice(0, offset) +
                    "<strong>" + text.slice(offset, offset+length) + "</strong>" +
                    text.slice(offset+length);

                return({label: html, value: text});
            }));
        });
    },
    select: function( event, ui ) {
        $(this).val(ui.item.value);
        // If we're on the home page (which has a form with one field) make selecting an address submit the form
        $("form.one-field").submit();
    }
});