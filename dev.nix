{ pkgs, ... }: 
  let firebase-ext = pkgs.fetchurl {
    url =
      "https://firebasestorage.googleapis.com/v0/b/firemat-preview-drop/o/vsix%2Ffirebase-vscode-0.2.2.vsix?alt=media&token=b2988765-50d5-4989-a592-de99a0d489bb";
    hash = "sha256-fQBDYynS/e1I+QMSQopjWGGT3YLeCoZ7WaeoI0R2t9M=";
    name = "firebase.vsix";
  };
  in {
    channel = "stable-23.11";
    packages = [
      (pkgs.postgresql_15.withPackages (p: [ p.pgvector ]))
      pkgs.nodejs_20
      pkgs.python3
      pkgs.nodePackages.pnpm
    ];
    
    env = {
      POSTGRESQL_CONN_STRING = "postgresql://user:mypassword@localhost:5432/dataconnect?sslmode=disable";
      FIRESQL_PORT = 9939;
    };
  
    idx.extensions = [
      "mtxr.sqltools-driver-pg"
      "mtxr.sqltools"
      "GraphQL.vscode-graphql-syntax"
      "${firebase-ext}"
    ];
  
    processes = {
      postgresRun = {
        command = "postgres -D local -k /tmp";
      };
    };

    idx = {
      workspace = {
        onCreate = {
          setup = "node download.mjs";
          postgres = ''
            PGHOST=/tmp psql --dbname=postgres -c "ALTER USER \"user\" PASSWORD 'mypassword';"
            PGHOST=/tmp psql --dbname=postgres -c "CREATE DATABASE dataconnect;"
            PGHOST=/tmp psql --dbname=dataconnect -c "CREATE EXTENSION vector;"
          '';
          npm-install = "pnpm i --prefix=./email-app";
        };
      };
      previews = {
        enable = true;
        previews = {
          web = {
            command = ["npm" "run" "dev" "--prefix" "./email-app" "--" "--port" "$PORT" "--hostname" "0.0.0.0"];
            manager = "web";
          };
        };
      };
    };
}
