refresh_panel_time = function(panel, data) {
  var panel_status_text = panel.find("span.time");

  var duration = null;

  // Calculate the duration to show.
  if (data.finished) {
    // Calculate finished_time - start_time.
    var finished_time = Date.parse(data.finish_time);
    var start_time = Date.parse(data.start_time);

    duration = finished_time - start_time;
  } else {
    // Calculate current time - start_time
    var current_time = Date.now();
    var start_time = Date.parse(data.start_time);

    duration = current_time - start_time;
  }

  var seconds = Math.floor((duration / 1000) % 60);
  var minutes = Math.floor((duration / 1000 / 60) % 60);
  var hours = Math.floor((duration / 1000 / 60 / 60));

  if (seconds < 10) {
    seconds = "0" + seconds;
  }
  if (minutes < 10) {
    minutes = "0" + minutes;
  }
  if (hours < 10) {
    hours = "0" + hours;
  }

  panel_status_text.text(hours + ":" + minutes + ":" + seconds);
}

refresh_panel = function(panel_id, panel, data) {
  var panel_status_label = panel.find("span.label");

  // Refresh the status label and running times.

  refresh_panel_time(panel, data);

  panel_status_label.removeClass("label-danger label-success label-default");

  if (data.finished && !data.errored) {
    panel_status_label.text("Finished");
    panel_status_label.addClass("label-success");
  } else if (data.finished && data.errored) {
    panel_status_label.text("Errored");
    panel_status_label.addClass("label-danger");
  } else {
    panel_status_label.text("Running");
    panel_status_label.addClass("label-default");
  }

  // Refresh the progress bar.
  var progress = 100 * data.pareto_points_found / model.total_pareto_points;
  console.log(progress);
  var progress_bar = panel.find("div.progress-bar");
  progress_bar.css("width", progress + "%")
  // Refresh the graph.
  var graph = d3.select("#" + panel_id + " svg");

  var xmin = 0;
  var xmax = model.metric_maximums[model.metrics[0]];
  var ymin = 0;
  var ymax = model.metric_maximums[model.metrics[1]];

  var graph_width = parseInt(graph.style("width"), 10);
  var graph_height = parseInt(graph.style("height"), 10);
  var x_padding = 50;
  var y_padding = 50;

  var xscaler = d3.scale.linear()
                        .domain([xmin, xmax])
                        .range([x_padding, graph_width - x_padding])
                        .nice();
  var yscaler = d3.scale.linear()
                        .domain([ymin, ymax])
                        .range([graph_height - y_padding, y_padding])
                        .nice();

  var x_axis_function = d3.svg.axis()
                              .scale(xscaler)
                              .orient("bottom");
  var y_axis_function = d3.svg.axis()
                              .scale(yscaler)
                              .orient("left");

  // Find the x-axis of the graph.
  var x_axis = graph.select("g.x-axis");
  if (x_axis.empty()) {
    x_axis = graph.append("g")
                  .classed("x-axis", true);
  }

  // Apply the axis function to it.
  x_axis.attr("transform", "translate(0,"+(graph_height - y_padding) + ")")
        .call(x_axis_function);

  // Find the y-axis of the graph.
  var y_axis = graph.select("g.y-axis");
  if (y_axis.empty()) {
    y_axis = graph.append("g")
                  .classed("y-axis", true);
  }

  // Apply the axis function to it.
  y_axis.attr("transform", "translate(" + x_padding + ",0)")
        .call(y_axis_function);

  // Draw the solutions.
  solutions = graph.select("g.solutions");
  if (solutions.empty()) {
    solutions = graph.append("g")
                     .classed("solutions", true);
  }

  // Update existing solution points.
  solutions = solutions.selectAll("circle")
                       .data(data.solutions)
                       .attr("cx", function(d) {
                          return xscaler(d[model.metrics[0]]);
                       })
                       .attr("cy", function(d) {
                          return yscaler(d[model.metrics[1]]);
                       })
                       .attr("r", 3)
                       .classed("solution", true);

  solutions.enter().append("circle")
                   .attr("cx", function(d) {
                      return xscaler(d[model.metrics[0]]);
                   })
                   .attr("cy", function(d) {
                      return yscaler(d[model.metrics[1]]);
                   })
                   .attr("r", 3)
                   .classed("solution", true);

  solutions.exit().remove();

  // Draw the pareto points.
  pareto_points = graph.select("g.pareto-points");
  if (pareto_points.empty()) {
    pareto_points = graph.append("g")
                         .classed("pareto-points", true);
  }

  // Update existing points
  pareto_points = pareto_points.selectAll("circle")
                               .data(data.pareto_points)
                               .attr("cx", function(d) {
                                  return xscaler(d[model.metrics[0]]) ;
                               })
                               .attr("cy", function(d) {
                                  return yscaler(d[model.metrics[1]]);
                               })
                               .attr("r", 4)
                               .classed("pareto-point", true);

  // Add new points
  pareto_points.enter().append("circle")
                       .attr("cx", function(d) {
                          return xscaler(d[model.metrics[0]]);
                       })
                       .attr("cy", function(d) {
                          return yscaler(d[model.metrics[1]]);
                       })
                       .attr("r", 4)
                       .classed("pareto-point", true);

  // Remove unneeded points.
  pareto_points.exit().remove();
};
