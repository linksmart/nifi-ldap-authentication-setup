package sk.tuke.monsoon.nifi.processors.kairosdb;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;
import org.apache.nifi.annotation.documentation.CapabilityDescription;
import org.apache.nifi.annotation.documentation.Tags;
import org.apache.nifi.annotation.lifecycle.OnScheduled;
import org.apache.nifi.annotation.lifecycle.OnUnscheduled;
import org.apache.nifi.components.PropertyDescriptor;
import org.apache.nifi.flowfile.FlowFile;
import org.apache.nifi.flowfile.attributes.CoreAttributes;
import org.apache.nifi.logging.ComponentLog;
import org.apache.nifi.processor.AbstractProcessor;
import org.apache.nifi.processor.ProcessContext;
import org.apache.nifi.processor.ProcessSession;
import org.apache.nifi.processor.ProcessorInitializationContext;
import org.apache.nifi.processor.Relationship;
import org.apache.nifi.processor.exception.ProcessException;
import org.apache.nifi.processor.io.InputStreamCallback;
import org.apache.nifi.processor.util.StandardValidators;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.kairosdb.client.Client;
import org.kairosdb.client.HttpClient;
import org.kairosdb.client.builder.Metric;
import org.kairosdb.client.builder.MetricBuilder;
import org.kairosdb.client.response.Response;

/**
 *
 * @author Peter Bednar
 */
@Tags({"kairosdb", "put", "http", "https"})
@CapabilityDescription("Writes FlowFiles to KairosDB using HTTP protocol")
public class PutKairosDB extends AbstractProcessor {

    private ComponentLog log;

    private String metricPrefix;
    private final AtomicReference<Client> clientAtomicReference = new AtomicReference<>();

    // Properties for this Processor
    public static final PropertyDescriptor KAIROSDB_BASE_URL = new PropertyDescriptor.Builder()
            .name("KairosDB Base URL")
            .description("Base URL for KairosDB: example: http://localhost:8080")
            .required(true)
            .expressionLanguageSupported(true)
            .addValidator(StandardValidators.URL_VALIDATOR)
            .build();

    public static final PropertyDescriptor METRIC_NAME_PREFIX = new PropertyDescriptor.Builder()
            .name("Metric Name Prefix")
            .description("Prefix for metric names: example: test")
            .required(false)
            .expressionLanguageSupported(true)
            .addValidator(StandardValidators.NON_BLANK_VALIDATOR)
            .build();
    
    /*
    public static final PropertyDescriptor COMPRESS_DATA = new PropertyDescriptor.Builder()
            .name("Compress Data")
            .description("If true, data will be GZIP compressed")
            .required(false)
            .allowableValues("true", "false")
            .defaultValue("false")
            .build();
    */

    // Releationships for this Processor
    public static final Relationship REL_SUCCESS = new Relationship.Builder().name("success")
            .description("Files that have been successfully written to KairosDB are transferred to this relationship")
            .build();

    public static final Relationship REL_FAILURE = new Relationship.Builder().name("failure")
            .description("Files that could not be written to KairosDB are transferred to this relationship")
            .build();

    private static final List<PropertyDescriptor> DESCRIPTORS;
    private static final Set<Relationship> RELATIONSHIPS;

    static {
        final List<PropertyDescriptor> innerDescriptorsList = new ArrayList<>();
        innerDescriptorsList.add(KAIROSDB_BASE_URL);
        innerDescriptorsList.add(METRIC_NAME_PREFIX);
        //innerDescriptorsList.add(COMPRESS_DATA);
        DESCRIPTORS = Collections.unmodifiableList(innerDescriptorsList);

        final Set<Relationship> innerRelationshipsSet = new HashSet<>();
        innerRelationshipsSet.add(REL_SUCCESS);
        innerRelationshipsSet.add(REL_FAILURE);
        RELATIONSHIPS = Collections.unmodifiableSet(innerRelationshipsSet);
    }

    @Override
    public Set<Relationship> getRelationships() {
        return RELATIONSHIPS;
    }

    @Override
    public final List<PropertyDescriptor> getSupportedPropertyDescriptors() {
        return DESCRIPTORS;
    }

    @Override
    protected void init(final ProcessorInitializationContext context) {
        this.log = getLogger();
    }

    @OnScheduled
    public void onScheduled(final ProcessContext context) {
        try {
            String baseURL = context.getProperty(KAIROSDB_BASE_URL).evaluateAttributeExpressions().getValue();
            metricPrefix = context.getProperty(METRIC_NAME_PREFIX).evaluateAttributeExpressions().getValue();
            if (metricPrefix == null) {
                metricPrefix = "";
            } else {
                metricPrefix = metricPrefix.trim();
                if (! metricPrefix.isEmpty()) {
                    metricPrefix += "_";
                }
            }

            // init HttpClient
            Client client = createClient(baseURL);
            clientAtomicReference.set(client);
        } catch (IllegalArgumentException | MalformedURLException | ProcessException e) {
            log.error(e.getLocalizedMessage());
        }
    }

    @OnUnscheduled
    public void onUnscheduled(final ProcessContext context) {
        try {
            Client client = clientAtomicReference.getAndSet(null);
            client.shutdown();
        } catch (IOException e) {
            log.error(e.getLocalizedMessage());
        }
    }

    @Override
    public void onTrigger(ProcessContext pc, ProcessSession ps) throws ProcessException {
        final FlowFile flowFile = ps.get();
        if (flowFile == null) {
            log.warn("FlowFile isn't set.");
            return;
        }

        String fileName = flowFile.getAttribute(CoreAttributes.FILENAME.key());
        fileName = fileName.trim();
        if (! fileName.endsWith(".json")) {
            log.warn("Not a JSON file. Routing to failure.");
            ps.transfer(flowFile, REL_FAILURE);
            return;
        }

        try {
            MetricBuilder metric = getMetric(flowFile, ps);
            Response response = clientAtomicReference.get().pushMetrics(metric);

            if (response.getStatusCode() == 204) {
                // Data was stored successfully, transfer to the sucess relationship
                ps.transfer(flowFile, REL_SUCCESS);
            } else {
                // Error response, transfer to the failure relationship
                logError(response);
                ps.transfer(flowFile, REL_FAILURE);
            }
        } catch (Exception e) {
            // Exception encounter, transfer to the failure relationship
            log.error("Routing to failure due to exception: {}", new Object[]{e}, e);
            ps.transfer(flowFile, REL_FAILURE);
        }
    }
    
    protected Client createClient(String baseURL) throws MalformedURLException {
        return new HttpClient(baseURL);
    }
    
    private static String[] getFileNameElements(String fileName) {
        if (fileName == null) {
            fileName = "";
        }
        fileName = fileName.trim();
        if (fileName.endsWith(".json")) {
            fileName = fileName.substring(0, fileName.length() - 5);
        }
        String str[] = fileName.split("---");
        return str;
    }

    private String getMetricName(FlowFile flowFile) {
        String fileName = flowFile.getAttribute(CoreAttributes.FILENAME.key());
        String str[] = getFileNameElements(fileName);
        String metricName = metricPrefix + str[str.length - 1];
        // metricName = metricName.replace('.', '_');
        return metricName;
    }

    private void addTags(Metric metric, FlowFile flowFile) {
        String fileName = flowFile.getAttribute(CoreAttributes.FILENAME.key());
        fileName = getFileNameElements(fileName)[0];
        metric.addTag("filename", fileName);
        // Extract aditional tags from the flowfile attributes
    }

    private JsonArray getContentJson(FlowFile flowFile, ProcessSession ps) throws IOException {
        AtomicReference<JsonArray> values = new AtomicReference<>();
        ps.read(flowFile, new InputStreamCallback() {
            @Override
            public void process(InputStream in) throws IOException {
                JsonParser parser = new JsonParser();
                InputStreamReader reader = new InputStreamReader(in, "utf-8");
                values.set((JsonArray) parser.parse(reader));
            }
        });
        return values.get();
    }

    private static final String EMPTY_STRING = "__empty__";
    private static final DateTimeFormatter TIMESTAMP_FORMATTER = DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

    private MetricBuilder getMetric(FlowFile flowFile, ProcessSession ps) throws IOException {
        JsonArray json = getContentJson(flowFile, ps);

        String type = null;
        for (JsonElement elm : json) {
            JsonPrimitive value = ((JsonObject) elm).get("value").getAsJsonPrimitive();
            if (value.isString()) {
                type = "string";
            }
            break;
        }

        MetricBuilder builder = MetricBuilder.getInstance();
        Metric metric = builder.addMetric(getMetricName(flowFile), type);
        addTags(metric, flowFile);

        for (JsonElement elm : json) {
            String timestamp = ((JsonObject) elm).get("timestamp").getAsString();
            long timestampMillis = TIMESTAMP_FORMATTER.parseDateTime(timestamp).getMillis();

            JsonPrimitive value = ((JsonObject) elm).get("value").getAsJsonPrimitive();
            if (value.isNumber()) {
                metric.addDataPoint(timestampMillis, value.getAsDouble());
            } else if (value.isString()) {
                String str = value.getAsString();
                if (str.isEmpty()) {
                    str = EMPTY_STRING;
                }
                metric.addDataPoint(timestampMillis, str);
            }
        }

        return builder;
    }

    private void logError(Response response) {
        log.error("Error response code {}: {}: Routing to failure", new Object[]{
            response.getStatusCode(),
            String.join(", ", response.getErrors())});
    }
    
}

