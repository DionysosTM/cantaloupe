# Cantaloupe IIIF Docker image

Docker Image from Teklia for the Cantaloupe IIIF image server

## Run Cantaloupe

Cantaloupe needs a configuration file in order to be executed.
You can bind your own configuration to `/etc/cantaloupe.properties` in the running container.
A configuration example is published on the Cantaloupe repository ([link](https://github.com/cantaloupe-project/cantaloupe/blob/release/5.0/cantaloupe.properties.sample)).

## Bump the image's version

When a new release of Cantaloupe is available, you can simply try to update the `VERSION` variable in the Dockerfiles.
Please ensure that it does not break the build and the server works correctly, otherwise you should probably update the corresponding Dockerfile.

It is necessary to update the version tag in the `.gitlab-ci.yml` file, as this process is not automated.

The new version will be published once merged into the main branch.

## Contributions

- [Fix TIFF Exif parsing](https://github.com/cantaloupe-project/cantaloupe/issues/548)
- [Unsafe reads](https://github.com/cantaloupe-project/cantaloupe/commit/7547c426dabb342a8adae31f9793c14fb1d073a2)
