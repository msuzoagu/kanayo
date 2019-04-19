# Kanayo
*kanayo* is a simple dockerized acme client wrapper used to obtain ssl certificates from letsencrypt using dns-auth for domains managed with DigitalOcean.

#### Instructions 
* build a customized image that uses `kanayo` as a parent image. This customized image will contain a configuration folder. 

* inside the configuration folder, you need to provide the following 3 files: 
    - an account key file
    - a certificate key file
    - a config.yaml file with the following key-value pairs: 
        ```
        provider:
          name: digitalocean
          token:your_digitalocean_token
        domains: 
          - your_domain_name
        email: address_used_for_acme_registration_and_renewal_notice
        ```


        In sum, the tree structure of your customized image should be: 
        ```
            .
            ├── Dockerfile
            └── configuration
                ├── account.key
                ├── certificate.key
                └── config.yml
        ```

        - `sample_dockerfile` contains an example Dockerfile 

* run `docker build -t your_dockerhub_username/your_image_name:version` to build a customized acme_client_wrapper image that you will use to generate, renew, or revoke ssl certificates you maintain.  

* SSH into your docker node and grab the following information: 
    ```
        - docker_user_id: `id -u docker_user_name`
        - docker_user_group_id: `id -g docker` 
            - replace `docker` with value of group docker_user belongs to
    ```

* Create a named volume to hold the generated ssl certificate `docker volume create vol_name`. 
    * alternatively, if running **docker swarm**, you could configure docker to use an external block storage device. This way, the storage device can be used to create secrets on manager nodes after which the storage device can be detaached and kept offline until you need to renew/revoke certificates. 

* Pull in your cutomized acme_client_wrapper image and run the following command: 
    ```
        docker run -ti \
        --mount type=volume,src=acme,dst=/home/docker \
        -e APP_USER=docker_user_name \
        -e APP_USER_ID=docker_user_id \
        -e APP_GROUP=docker_user_group \
        -e APP_GROUP_ID=docker_user_group_id \
        --name test your_dockerhub_username/your_image_name:version /bin/sh
    ```
 
    - running `cli --help` prints all the commands available to you. 
        - currently only supports ssl certificate generation

#### Note on Configuration
As of today, I haven't added code that deletes the configuration folder after ssl certs are generated/renewed/revoked. This is a todo as I need to decide if: 
 - it is best to pass all configuration values in via the command line *OR*
 - regenerate the account and private keys each time `kanyo` while passing in cloud_provider and its associated token via cmdline 
