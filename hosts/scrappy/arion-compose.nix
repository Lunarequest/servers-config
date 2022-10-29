{
  services = rec {
    database = {
      service.image = "postgres";
      service.volumes = ["/var/lib/blog/pgdata:/var/lib/postgresql/data"];
      service.environment = {
        POSTGRES_USER = "blog";
        POSTGRES_PASSWORD = "blog";
      };
    };
    web = {
      service.image = "ghcr.io/lunarequest/blog/stable";
      service.depends_on = [
        "database"
      ];
      service.environment = {
        ROCKET_PROFILE = "prod";
        ROCKET_LOG_LEVEL = "normal";
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_SECRET_KEY = "Y6HLswYTBwS3H51OfL8O5htSvVDLxYr5XjREo7g2TW8=";
        ROCKET_DATABASES = "{blog={url=\"postgres://blog:blog@database:5432/blog\"}}";
        SECRET_KEY = "0xE3af2f0f00AA3E2D788398Cac048A38F8C8F254E";
        SITE_KEY = "4059a6d8-8955-4291-8955-9e04d5d22230";
      };
      service.ports = [
        "8000:8000"
      ];
      service.volumes = ["/var/lib/blog/assets:/assets"];
      service.restart = "on-failure";
    };
  };
}
