class Shoes::App
  def supports_onclose?
    methods.include? 'onclose'
  end
end

# This positioning doesn't appear to work... I wonder how to do it right?
a = Shoes.app :left => 10, :top => 10 do
  Shoes.log.clear
  @apps = []
  para "Enter shoes code and submit to see a demo of what it would look like"
  @e = edit_box :height => 200, :width => '100%'
  @e.focus

  # Would like to have hotkeys for each button, but its unclear how to catch
  # things like ctrl-s from inside the edit_box
  @submit = button "Submit"
  @submit.click do 
    app = if @e.text.grep(/Shoes.app/).empty?
      eval "Shoes.app { #{@e.text} }"
    else
      eval @code
    end
    @apps.push app
    if app.supports_onclose?
      app.onclose do
        Shoes.info "A sample app just closed"
        @apps.delete(app) 
      end
    end
  end

  @clear = button "Clear"
  @clear.click do 
    @e.text = ''
    @err.text = ''
    Shoes.log.clear
   end

  @delete = button "Remove Demo Apps"
  @delete.click do
    open_app_ids = Shoes.APPS.map {|a| a.id}
    @apps.each do |a| 
      a.close if open_app_ids.include? a.id
    end
    @apps = []
  end

  @load = button "Load from file"
  @load.click do
    filename = ask_open_file
    @e.text = File.read(filename)
  end
  every(1) do
    Shoes.log.each do |typ, msg, at, mid, rbf, rbl|
      @err.text = "#{msg}"
    end
  end

  @save = button "Save to file"
  @save.click do
    filename = ask_save_file
    f = File.open(filename, 'w')
    f.write(@e.text)
    f.close
  end
  @e.focus
  para "============= Error Messages ==============", :align => 'center'
  @err = edit_box :height => 200, :width => '100%'
end
