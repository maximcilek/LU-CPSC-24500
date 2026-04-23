@Service
public class NamesIngestionService {

    private final NameRepository repo;

    public NamesIngestionService(NameRepository repo) {
        this.repo = repo;
    }

    public void loadFromParquet(String pathStr) throws Exception {

        Path path = Paths.get(pathStr);

        ParquetReader<GenericRecord> reader =
            AvroParquetReader.<GenericRecord>builder(
                new org.apache.hadoop.fs.Path(path.toUri())
            ).build();

        GenericRecord record;

        while ((record = reader.read()) != null) {
            repo.save(new Name(
                record.get("name").toString(),
                (int) record.get("year"),
                record.get("sex").toString(),
                (int) record.get("rank"),
                (int) record.get("count")
            ));
        }

        reader.close();
    }
}