def s3source_object_info(options = {})
  identifier = context['identifier']

  # Nettoyage si /iiif/2/ est présent dans l'identifiant
  if identifier.start_with?("/iiif/2/")
    identifier = identifier.sub("/iiif/2/", "")
  end

  # Supprimer tout ce qui suit un slash s’il y en a (IIIF format, params, etc.)
  identifier = identifier.split('/').first

  # Séparer le bucket et la clé à partir du séparateur "~"
  if identifier.include?("~")
    bucket, *key_parts = identifier.split("~")
    key = key_parts.join("~")  # au cas où la clé contient aussi des '~'
    return {
      bucket: bucket,
      key: key
    }
  else
    # fallback: log, ou retour nil pour indiquer erreur
    puts "[Delegate] Identifiant invalide: #{identifier}"
    return nil
  end
end
