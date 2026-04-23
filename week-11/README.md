baby-names-api/
│
├── backend/                          # Spring Boot API
│   ├── src/main/java/com/babynames/
│   │   ├── controller/
│   │   │   └── NameController.java
│   │   │
│   │   ├── service/
│   │   │   └── NameService.java
│   │   │
│   │   ├── repository/
│   │   │   └── NameRepository.java
│   │   │
│   │   ├── model/
│   │   │   └── NameRecord.java
│   │   │
│   │   ├── dto/                      # generated from protobuf
│   │   │   └── NameResponse.java
│   │   │
│   │   ├── mapper/
│   │   │   └── ProtoMapper.java
│   │   │
│   │   └── BabyNamesApplication.java
│   │
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   └── schema.sql (optional init)
│   │
│   └── pom.xml
│
├── proto/                            # 🔥 CENTRALIZED SCHEMAS
│   ├── name.proto
│   ├── age.proto (optional)
│   └── build.gradle / maven plugin config
│
├── database/
│   ├── baby_names.db                 # SQLite file (or generated)
│   └── init.sql                      # schema + seed script
│
├── docker/
│   ├── Dockerfile.backend
│   ├── Dockerfile.db (optional)
│   └── docker-compose.yml
│
├── data/
│   └── baby_names.csv
│
├── scripts/
│   ├── load_to_sqlite.py (optional helper)
│   └── ingest.sh
│
├── README.md
└── .gitignore