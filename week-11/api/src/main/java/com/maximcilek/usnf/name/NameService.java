package om.maximcilek.usnf.service;

import om.maximcilek.usnf.dto.NameResponse;
import om.maximcilek.usnf.model.NameRecord;
import om.maximcilek.usnf.repository.NameRepository;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class NameService {

    private final NameRepository repository;

    public NameService(NameRepository repo) {
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

    public NameResponse getNameInfo(String name) {
        List<NameRecord> records = repo.findByName(name);

        if (records.isEmpty()) {
            return new NameResponse(name, 0, 0, 0, List.of());
        }

        // first year
        int firstYear = records.stream()
                .mapToInt(NameRecord::getYear)
                .min()
                .orElse(0);

        // most popular year (by total count)
        Map<Integer, Integer> yearTotals = new HashMap<>();
        for (NameRecord r : records) {
            yearTotals.put(r.getYear(),
                    yearTotals.getOrDefault(r.getYear(), 0) + r.getCount());
        }

        int mostPopularYear = yearTotals.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse(0);

        // top 10 years
        List<Integer> topYears = yearTotals.entrySet().stream()
                .sorted((a, b) -> b.getValue() - a.getValue())
                .limit(10)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());

        // estimated age (simple heuristic: latest year - first appearance)
        int estimatedAge = 2024 - firstYear;

        return new NameResponse(name, estimatedAge, firstYear, mostPopularYear, topYears);
    }
}