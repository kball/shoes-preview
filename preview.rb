class DemoApp
  def initialize(code)
    @clearode = code
    @app = if code.grep(/Shoes.app/).empty?
      eval "Shoes.app { #{code} }"
    else
      eval @clearode
    end
  end
  def close
    @app.close
  end
end

a = Shoes.app do
  @apps = []
  para "Enter shoes code and submit to see a demo of what it would look like"
  @e = edit_box :height => 200, :width => '100%'

  @submit = button "Submit"
  @submit.click { @apps.push DemoApp.new(@e.text) }

  @clear = button "Clear"
  @clear.click {@e.text = ''}

  @delete = button "Remove Demo Apps"
  @delete.click do 
    @apps.each {|a| a.close}
    @apps = []
  end

  @load = button "Load from file"
  @load.click do
    filename = ask_open_file
    @e.text = File.read(filename)
  end
  @e.focus
end
