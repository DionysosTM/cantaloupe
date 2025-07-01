class CustomDelegate

  def initialize(context)
    @context = context
  end

  # Appelé pour résoudre l’image à charger
  def source
    return "S3Source"
  end

  def s3_source_bucket
    # Exemple : toutes les images dans le bucket `images`
    return "images"
  end

  def s3_source_key
    # Utilise l'identifiant de l'URL comme clé S3 (ex: image1.jpg)
    return @context.getIdentifier()
  end

end
