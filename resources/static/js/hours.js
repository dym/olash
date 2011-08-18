var pct;
var advice_number;
google.load('visualization', '1', {packages: ['gauge']});
google.setOnLoadCallback(drawChart);
// Refresh every 10 minutes
var holdInterval = window.setInterval(function(){drawChart();}, 600000);
function drawChart() {
    levels = [50, 75, 99.9, 110];
    advices = [
        ["Ways to go...", "Get working, now !", "You know, you are not on a vacation"],
        ["Lot done and a lot yet to do", "Work hard now to play hard later", "Please continue the good work"],
        ["The end is near", "Just a bit more", "We will be victorious!"],
        ["Stop or you'll get blind !", "Workaholics anonymous is your friend", "Get a life!"]
    ];
    $.ajax("/util/hours/", {
               dataType: 'json',
               success: function(return_data, textStatus, jqXhr) {
                   pct = return_data['result'];
                   if ((typeof(pct) != "undefined") && (pct != "empty")) {
                           pct = eval(pct);
                           if (pct > 100)
                               pct = 100;
                           var data = new google.visualization.DataTable();
                           data.addColumn('string', 'Label');
                           data.addColumn('number', 'Value');
                           data.addRows(1);
                           data.setValue(0, 0, '% Done');
                           data.setValue(0, 1, pct);
                           var chart = new google.visualization.Gauge(document.getElementById('gauge'));
                           var options = {width: 300, height: 300, redFrom: 0, redTo: levels[0],
                                          yellowFrom:levels[2], yellowTo: levels[3], greenFrom: levels[1], greenTo: levels[2],
                                          redColor: '#D05922', yellowColor: '#F08800', greenColor: '#209020', minorTicks: 5};
                           chart.draw(data, options);
                           $('.advice .button').removeAttr('disabled');
                           show_message();
                       }
                      }
                       });
          }
    function show_message() {
        var random_advice_num;
        for (i=0; i < levels.length && pct > levels[i]; i++)
            ;
            do {
                random_advice_num = Math.floor(Math.random()*3);
            } while (random_advice_num == advice_number);
        advice_number = random_advice_num;
        $('.advice_text').text(advices[i][random_advice_num]);
    }