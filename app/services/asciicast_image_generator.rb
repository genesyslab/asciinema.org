class AsciicastImageGenerator
  PIXEL_DENSITY = 2

  attr_reader :template_renderer, :rasterizer, :image_inspector

  def initialize(template_renderer, rasterizer = Rasterizer.new, image_inspector = ImageInspector.new)
    @template_renderer = template_renderer
    @rasterizer = rasterizer
    @image_inspector = image_inspector
  end

  def generate(asciicast)
    Dir.mktmpdir do |dir|
      page_path = "#{dir}/asciicast.html"
      image_path = "#{dir}/#{asciicast.image_filename}"

      generate_html_file(asciicast, page_path)
      generate_png_file(page_path, image_path)
      image_width, image_height = get_size(image_path)

      update_asciicast(asciicast, image_path, image_width, image_height)
    end
  end

  private

  def generate_html_file(asciicast, path)
    html = template_renderer.render_to_string(
      template: 'asciicasts/screenshot.html.slim',
      layout: 'screenshot',
      locals: { page: BareAsciicastPagePresenter.build(asciicast) },
    )

    File.open(path, 'w') { |f| f.write(html) }
  end

  def generate_png_file(page_path, image_path)
    rasterizer.generate_image(page_path, image_path, 'png', '.asciinema-player', PIXEL_DENSITY)
  end

  def get_size(image_path)
    width, height = image_inspector.get_size(image_path)

    # "display" size is 1/PIXEL_DENSITY of the actual one
    [width / PIXEL_DENSITY, height / PIXEL_DENSITY]
  end

  def update_asciicast(asciicast, image_path, image_width, image_height)
    File.open(image_path) do |f|
      asciicast.image = f
    end

    asciicast.image_width = image_width
    asciicast.image_height = image_height

    asciicast.save!
  end

end
