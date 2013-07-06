module RearHelpers
  module InstanceMixin

    def image? file
      (@@__rear__image_files ||= Hash[ASSETS__IMAGE_FILES.zip(ASSETS__IMAGE_FILES)])[File.extname(file)]
    end
    
    def video? file
      (@@__rear__video_files ||= Hash[ASSETS__VIDEO_FILES.zip(ASSETS__VIDEO_FILES)])[File.extname(file)]
    end

    def browseable? file
      image?(file) || video?(file)
    end

  end
end
