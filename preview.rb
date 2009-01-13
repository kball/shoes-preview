class DemoApp
  def initialize(code)
    @code = code
    @app = if code.grep(/Shoes.app/).empty?
      eval "Shoes.app { #{code} }"
    else
      eval @code
    end
  end
  def id
    @app.id
  end
  def close
    @app.close
  end
end

# This positioning doesn't appear to work... I wonder how to do it right?
a = Shoes.app :left => 10, :top => 10 do
  @apps = []
  para "Enter shoes code and submit to see a demo of what it would look like"
  @e = edit_box :height => 200, :width => '100%'
  @e.focus

  # Would like to have hotkeys for each button, but its unclear how to catch
  # things like ctrl-s from inside the edit_box
  @submit = button "Submit"
  @submit.click { @apps.push DemoApp.new(@e.text) }

  @clear = button "Clear"
  @clear.click {@e.text = ''}

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
  @e.focus
end
