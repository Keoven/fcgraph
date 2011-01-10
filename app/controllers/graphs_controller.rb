class GraphsController < ApplicationController

  def new
  end

  def index
    unless params[:log_file]
      redirect_to root_path
    else
      begin
        @graph = generate_graph(params[:log_file])
      rescue Exception => e
        redirect_to root_path
      end
    end
  end

  private
  def generate_graph(file)
    file.read.each_line do |line|
      parse_line(line)
    end

    graphs = []
    tags = ['<ul class="idTabs">']

    x_labels = OFC2::XAxisLabels.new
    step = @turns.size.to_s.length <= 1 ? 1 : (
             10 ** (@turns.size.to_s.length - 2) * 3
           )
    x_labels.labels = []
    0.upto(@turns.size/step) do |i|
      turn = i * step
      x_labels.labels[turn] = OFC2::XAxisLabel.new(
        :text   => @turns[turn][:description],
        :colour => '#888888',
        :size   => 12,
        :rotate => 70)
    end
    x_labels.labels.map! do |label|
      label ||= ''
    end

    x_axis = OFC2::XAxis.new
    x_axis.labels = x_labels

    @tags.each do |t_id, tag|
      max_value = 0
      tags << "<li><a href=\"#idTab#{t_id}\" #{ 'class="selected"' if tag.eql?('score')}>#{I18n.t("graphs.#{tag}")}</a></li>"

      chart = OFC2::Graph.new
      chart.bg_colour = "#111111"
      chart.x_axis = x_axis
      chart.title = OFC2::Title.new(
        :text => I18n.t("graphs.#{tag}"),
        :style => "{font-family: Cambria; font-size: 40px; color: #FFFFFF; text-align: left; font-weight: bold;}"
      )

      @players.each do |p_id, player|
        line = OFC2::Line.new
        line.colour = player[:color]
        line.text = player[:nation] ? player[:nation].name : player[:name]
        line.values = []

        @data = @data.select do |d|
          if(player == d[:player] && tag == d[:tag])
            line.values[@turns.index(d[:turn])] = d[:value]
            max_value = d[:value] if max_value < d[:value]
            false
          else
            true
          end
        end
        line.values.map! {|v| v.nil? ? 0 : v }

        chart << line
      end

      step = if max_value.to_s.length <= 1
               1
             elsif max_value <= 20
               5
             else
               temp = 10 ** (max_value.to_s.length - 2) * 3
               temp = 10 if temp.to_s.length <= 1
               temp
             end

      chart.y_axis = OFC2::YAxis.new(
                       :min   => 0,
                       :max   => ((max_value/step) + 1).floor * step,
                       :steps => step
                     )
      axis_colour = '#080808'
      chart.y_axis.colour = axis_colour
      chart.y_axis.grid_colour = axis_colour
      y_labels = OFC2::YAxisLabels.new
      y_labels.colour = '#888888'
      chart.y_axis.labels = y_labels

      chart.x_axis.colour = axis_colour
      chart.x_axis.grid_colour = axis_colour

      graphs << <<-EOS
        <div id="idTab#{t_id}" style="display: #{tag.eql?('score') ? 'block' : 'none'};">
          #{ ofc2_inline(650, 400, chart, "inline_chart_#{tag}")}
        </div>
      EOS
    end
    tags << '</ul>'

    tags.join + graphs.join
  end

  def parse_line(line)
    line = line.split
    case line[0]
    when 'id'
      @game_id = line[1]
    when 'tag'
      @tags ||= {}
      @tags[line[1].to_i] = line[2]
    when 'turn'
      @turns ||= {}
      @turns[line[1].to_i] = {
        :year        => line[2],
        :description => line.drop(3).join(' ')
      }
    when 'addplayer'
      @players ||= {}
      player_name = line.drop(3).join(' ')

      golden_ratio_conjugate = 0.618033988749895
      h = (rand + golden_ratio_conjugate) % 1
      s = (rand + golden_ratio_conjugate) % 1
      color = hsv_to_rgb(h, s, 0.95)
      @players[line[2].to_i] = {
        :add  => line[1].to_i,
        :name => player_name,
        :color => "#%02x%02x%02x".%(color),
        :nation => Leader.find_by_name(player_name).try(:nation)
      }
    when 'delplayer'
      @players[line[2].to_i][:remove] = line[1].to_i
    when 'data'
      @data ||= []
      @data << {
        :turn   => @turns[line[1].to_i],
        :tag    => @tags[line[2].to_i],
        :player => @players[line[3].to_i],
        :value  => line[4].to_i
      }
    end
  end

  ## HSV values in [0..1[
  #  returns [r, g, b] values from 0 to 255
  #  http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
  def hsv_to_rgb(h, s, v)
    h_i = (h*6).to_i
    f = h*6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)
    r, g, b = v, t, p if h_i==0
    r, g, b = q, v, p if h_i==1
    r, g, b = p, v, t if h_i==2
    r, g, b = p, q, v if h_i==3
    r, g, b = t, p, v if h_i==4
    r, g, b = v, p, q if h_i==5
    [(r*256).to_i, (g*256).to_i, (b*256).to_i]
  end

end
