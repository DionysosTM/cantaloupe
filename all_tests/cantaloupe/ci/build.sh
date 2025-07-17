#!/bin/sh -e
# Build a Cantaloupe Docker image.
# Requires CI_PROJECT_DIR and CI_REGISTRY_IMAGE to be set.
# IMAGE_TAG must match the Cantaloupe version.
# Will only push an image if the commit is on the main branch.
# Will automatically login to a registry if CI_REGISTRY, CI_REGISTRY_USER and CI_REGISTRY_PASSWORD are set.

IMAGE_TAG=$(cat VERSION)

if [ -z "$IMAGE_TAG" -o -z "$CI_PROJECT_DIR" -o -z "$CI_REGISTRY_IMAGE" ]; then
	echo Missing environment variables
	exit 1
fi

docker build $CI_PROJECT_DIR -f $CI_PROJECT_DIR/Dockerfile -t "$CI_REGISTRY_IMAGE:$IMAGE_TAG"

# Publish the image on the main branch or on a tag
if [ "$CI_COMMIT_REF_NAME" = "main" ]; then
  if [ -n "$CI_REGISTRY" -a -n "$CI_REGISTRY_USER" -a -n "$CI_REGISTRY_PASSWORD" ]; then
    echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
    docker push "$CI_REGISTRY_IMAGE:$IMAGE_TAG"
  else
    echo "Missing environment variables to log in to the container registry…"
  fi
else
  echo "The build will only be published when commited to the main branch…"
fi
