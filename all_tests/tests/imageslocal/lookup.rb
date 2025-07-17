# /etc/lookup.rb
#
# Retourne le bucket et la clé S3 à partir de l’identifiant IIIF.
# Exemple :  /iiif/3/image1.jpg  → identifier = "image1.jpg"

def get_s3_source_object_info(identifier)
  {
    "bucket" => "images",      # nom exact du bucket MinIO
    "key"    => identifier     # ex. "image1.jpg"
  }
end
