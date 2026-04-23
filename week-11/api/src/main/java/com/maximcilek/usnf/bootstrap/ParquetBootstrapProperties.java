@Component
@ConfigurationProperties(prefix = "bootstrap.parquet")
public class ParquetBootstrapProperties {

    private boolean enabled;
    private String namesPath;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getNamesPath() {
        return namesPath;
    }

    public void setNamesPath(String namesPath) {
        this.namesPath = namesPath;
    }
}