@Profile("dev")
@ConditionalOnProperty(name="bootstrap.parquet.enabled", havingValue="true")
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
@Profile("dev")
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