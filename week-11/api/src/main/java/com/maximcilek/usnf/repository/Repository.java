package om.maximcilek.usnf.repository;

import om.maximcilek.usnf.model.NameRecord;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class NameRepository {

    private final String url = "jdbc:sqlite:database/baby_names.db";

    public List<NameRecord> findByName(String name) {
        List<NameRecord> results = new ArrayList<>();

        String sql = "SELECT year, sex, name, count, rank FROM baby_names WHERE name = ?";

        try (Connection conn = DriverManager.getConnection(url);
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, name);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                results.add(new NameRecord(
                        rs.getInt("year"),
                        rs.getString("sex"),
                        rs.getString("name"),
                        rs.getInt("count"),
                        rs.getInt("rank")
                ));
            }

        } catch (SQLException e) {
            throw new RuntimeException("DB query failed", e);
        }

        return results;
    }
}