@Component
@ConfigurationProperties(prefix = "bootstrap.database")
public class DatabaseBootstrapperProperties {
    private boolean enabled;
    private String initDataFilepath;

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getInitDataFilepath() {
        return initDataFilepath;
    }

    public void setInitDataFilepath(String fp) {
        this.initDataFilepath = fp;
    }
}

// @Profile("")
@ConditionalOnProperty(name = "bootstrap.parquet.enabled", havingValue = "true")
@Component
public class NamesDatasetBootstrapper implements ApplicationRunner {

    private final NamesBootstrapService service;
    private final ParquetBootstrapProperties props;

    public NamesDatasetBootstrapper(
            NamesBootstrapService service,
            ParquetBootstrapProperties props
    ) {
        this.service = service;
        this.props = props;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        service.loadFromParquet(props.getNamesPath());
    }
}

"""
@Component
public class NamesDatasetBootstrapper implements ApplicationRunner {

    private final NamesBootstrapService service;

    public NamesDatasetBootstrapper(NamesBootstrapService service) {
        this.service = service;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        service.loadFromParquet("data/names.parquet");
    }
}
"""