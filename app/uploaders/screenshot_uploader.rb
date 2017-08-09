class ScreenshotUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  #storage :file
  #storage :fog
  process :to_jpeg => [800, 450]
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if model.class == Image
      "uploads/post/#{model.post_id}"
    else
      "uploads/post/#{model.id}"
    end
  end

  def extension_whitelist
     %w(png jpg jpeg gif)
  end

  def filename
    "frame" if original_filename
  end

  private

  def to_jpeg(width, height)
    manipulate! do |img|
      img.format("jpeg") do |c|
        c.resize      "#{width}x#{height}<"
        c.resize      "#{width}x#{height}>"
      end
      img
    end
  end
  
  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_whitelist
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end