import "@typespec/rest";
import "@typespec/http";
import "@azure-tools/typespec-azure-core";
import "@azure-tools/typespec-azure-resource-manager";

using TypeSpec.Rest;
using TypeSpec.Http;
using Azure.Core;
using Azure.ResourceManager;

namespace Microsoft.RedHatOpenshift;

/*
* ===================================
*   HyperShift cluster core resources
* ===================================
*/

/** HyperShift cluster resource */
model HcpOpenShiftClusterResource is TrackedResource<HcpOpenShiftClusterProperties> {
  /** Name of HyperShift cluster */
  @pattern("^[a-zA-Z0-9-]{3,24}$")
  @minLength(3)
  @maxLength(24)
  @key("hcpOpenShiftClusterName") // sets the alternative name for the name propery
  @path
  @segment("hcpOpenShiftClusters")
  name: string;

  ...ManagedServiceIdentity;
}

// The NodePool needs to be TrackedResource for the following reasons:
// - allow tags to be in place, which allows billing to use tags, important for workers
// - allow nodepool to be tracked in the portal
// - deleted when resource group is deleted
// - allow cascade delete
// more: https://armwiki.azurewebsites.net/rp_onboarding/tracked_vs_proxy_resources.html
@parentResource(HcpOpenShiftClusterResource)
model HcpOpenShiftClusterNodePoolResource is TrackedResource<NodePoolProperties> {
  /** Name of HyperShift cluster */
  @pattern("^[a-zA-Z0-9-]{3,24}$")
  @minLength(3)
  @maxLength(24)
  @key("nodePoolName")
  @path
  @segment("nodePools")
  name: string;
}

/** HyperShift cluster properties */
model HcpOpenShiftClusterProperties {
  /** The status of the last operation. */
  @visibility("read")
  provisioningState?: ProvisioningState;

  @visibility("create", "update")
  spec: ClusterSpec;
}

model ClusterSpec {
  /** Version of the control plane components */
  @visibility("create", "update")
  version: VersionProfile;

  /** Cluster DNS configuration */
  dns?: DnsProfile;

  /** Cluster network configuration */
  @visibility("create")
  network?: NetworkProfile;

  /** Configures the cluster web console */
  @visibility("read")
  console: ConsoleProfile;

  /** Configures the cluster API server profile */
  @visibility("read")
  api: ApiProfile;

  /** Enable FIPS mode for the cluster */
  @visibility("create")
  fips?: boolean = false;

  /** Enables ETCD encryption, set during creation */
  @visibility("create")
  etcdEncryption?: boolean = false;

  @visibility("create", "update")
  disableUserWorkloadMonitoring?: boolean = false;

  /** Openshift cluster proxy configuration */
  @visibility("create", "update")
  proxy?: ProxyProfile;

  @visibility("create", "update")
  additionalTrustBundle?: string;

  /** Azure specific configuration */
  @visibility("create")
  platform: PlatformProfile;

  /** URL for the OIDC provider */
  @visibility("read")
  issuerUrl: string;

  /* Configuration to override the OpenShift auth server inside cluster */
  @visibility("create")
  externalAuth?: ExternalAuthProfile[];

  /** Configures the cluster ingresses */
  @visibility("create", "update")
  ingress?: IngressProfile[];

  /** Worker node pools configuration, readonly.
   * The NodePool is always created during day-2 operations.
   * Using its separate endpoint.
   */
  @visibility("read")
  nodePools: NodePoolProfile[];
}

/** The resource provisioning state. */
@lroStatus
enum ProvisioningState {
  ...ResourceProvisioningState,
}

/** Versions represents an OpenShift version. */
model VersionProfile {
  /* ID is the unique identifier of the version. */
  @visibility("create", "update")
  id: string;

  /* ChannelGroup is the name of the set to which this version belongs. Each version belongs to only a single set. */
  @visibility("create")
  channelGroup: string;

  /* AvailableUpgrades is a list of version names the current version can be upgraded to. */
  @visibility("read")
  availableUpgrades: string[];
}

/** DNS contains the DNS settings of the cluster */
model DnsProfile {
  /* BaseDomain is the base DNS domain of the cluster. */
  @visibility("read")
  baseDomain: string;

  /* BaseDomainPrefix is the unique name of the cluster representing the OpenShift's cluster name. */
  /* BaseDomainPrefix is the name that will appear in the cluster's DNS, provisioned cloud providers resources */
  @visibility("create")
  baseDomainPrefix: string;
}

/** Network profile of the cluster */
model NetworkProfile {
  /* The main controller responsible for rendering the core networking components */
  @visibility("create")
  networkType: NetworkType;

  /** The CIDR of the pod IP addresses, for example 10.128.0.0/14 */
  @visibility("create")
  podCidr: string;

  /** The CIDR block for assigned service IPs, for example 172.30.0.0/16 */
  @visibility("create")
  serviceCidr: string;

  /** from which to assign machine IP addresses, for example 10.0.0.0/16 */
  @visibility("create")
  machineCidr: string;

  /** Network host prefix which is defaulted to 23 if not specified. */
  @visibility("create")
  hostPrefix?: int32 = 23;
}

enum NetworkType {
  sdn:   "OpenShiftSDN",
  ovn:   "OVNKubernetes",
  other: "Other",
}

/** Configuration of the cluster web console */
model ConsoleProfile {
  /** The cluster web console URL endpoint */
  @visibility("read")
  url: string;
}

/** Information about the API of a cluster. */
model ApiProfile {
  /** URL endpoint for the API server */
  @visibility("read")
  url: string;

  /** ip address of the API server */
  @visibility("read")
  ip: string;

  /** should the API server be accessible from the internet */
  @visibility("create")
  visibility: Visibility;
}

/** The visibility of the API server */
enum Visibility {
  /** The API server is visible from the internet. */
  public: "public",

  /** The API server is not visible from the internet. */
  private: "private",
}

/** OpenShift cluster proxy configuration */
model ProxyProfile {
  /** http proxy config */
  httpProxy: string;

  /** https proxy config */
  httpsProxy: string;

  /** no proxy config */
  noProxy: string;

  /** The trusted CA for the proxy */
  trustedCa: string;
}

/** Azure specific configuration */
model PlatformProfile {
  location: string;

  /** Resource group to put cluster resources */
  managedResourceGroup: string;

  vnetName: string;

  vnetId: string

  /** ResourceId for the subnet used by the control plane */
  subnetName: string;

  subscriptionId: string;

  machineIdentityId: string;

  securityGroupName: string;

  /** The core outgoing configuration */
  outboundType?: OutboundType = loadBalancer;

  /** Specifies whether subnets are pre-attached with an NSG */
  preconfiguredNsgs: boolean;

  /* Allow customer to specify custom encryption keys for etcd. */
  etcdEncryption?: EtcdEncryptionProfile;
}

/** The outbound routing strategy used to provide your cluster egress to the internet. */
enum OutboundType {
  /** The loadbalancer configuration */
  loadBalancer: "loadBalancer",
}

/** Etcd encryption profile sets the configuration needed for
 * customer brought keys to encrypt the etcd.
 * This is an optional field, if omitted the default encryption key is used.
 * TODO: decide how this is going to be implemented
*/
model EtcdEncryptionProfile {
  /** The id of the disk encryption set to be used for etcd
   * Is relies on https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-overview
  */
  discEncryptionSetId: string;
}

/*
* =======================================
*   End HyperShift cluster core resources
* =======================================
*/

/*
* =======================================
*  ExternalAuth resources
* =======================================
*/

model ExternalAuthProfile {
  issuer: TokenIssuerProfile;
  clients: ExternalAuthClientProfile[];
  claim: ExternalAuthClaimProfile;
}

model TokenIssuerProfile {
  url: string;
  audiences: string[];
  ca: string;
}

model ExternalAuthClientProfile {
  component: ExternalAuthClientComponentProfile;
  id: string;
  secret: string;
  extraScopes: string[];
}

model ExternalAuthClientComponentProfile {
  name: string;
  namespace: string;
}

model ExternalAuthClaimProfile {
  mappings: TokenClaimMappingsProfile;
  validationRules: TokenClaimValidationRuleProfile[];
}

model TokenClaimMappingsProfile {
  username: ClaimProfile;
  groups: ClaimProfile;
}

model ClaimProfile {
  claim: string;
  prefix: string;
  prefixPolicy: string;
}

model TokenClaimValidationRuleProfile {
  claim: string;
  requiredValue: string;
}

/*
* =======================================
*  End ExternalAuth resources
* =======================================
*/

/*
* =======================================
*  Ingress resources
* =======================================
*/

/** Configuration of the cluster ingress */
model IngressProfile {
  /** The IP for the ingress */
  @visibility("read")
  ip: string;

  /** The ingress url */
  @visibility("read")
  url: string;

  /** The visibility of the ingress */
  @visibility("create")
  visibility: Visibility;
}

/*
* =======================================
*  End Ingress resources
* =======================================
*/

/*
* =======================================
*  NodePool resources
* =======================================
*/

/** Represents the node pool properties */
model NodePoolProperties {
  /** Provisioning state */
  @visibility("read")
  provisioningState?: ResourceProvisioningState;

  /** Node pool profile */
  profile: NodePoolProfile;
}

/** Worker node pool profile */
model NodePoolProfile {
  /** The name of the worker pool */
  name: string;

  /** OpenShift version for the nodepool */
  version: string;

  /** Labels for the nodes */
  labels: string[];

  /** Taints for the nodes */
  taints: string[];

  /** The OS disk size in GB */
  diskSize: int32;

  /** IS the disk ephemeral */
  ephemeralOsDisk: boolean;

  /** The number of worker nodes, it cannot be used together with autoscaling */
  replicas: int32;

  /** The Azure resourceId for the subnet used by the workers */
  subnetId: string;

  /** Azure; Whether the worker machines should be encrypted at host */
  encryptionAtHost: boolean;

  /** Autorepair */
  autoRepair: boolean;

  /**  */
  discEncryptionSetId: string;

  /** */
  tuningConfigs: string[];

  /** The availability zone for the node pool */
  availabilityZone: string;

  /** The type of the disc storage account */
  discStorageAccountType: string;

  /** The VM size according to the documentation:
   * - https://learn.microsoft.com/en-us/azure/virtual-machines/sizes */
  vmSize: string;

  /** Representation of a autoscaling in a node pool. */
  autoscaling: NodePoolAutoscaling;
}

/** Node pool autoscaling */
model NodePoolAutoscaling {
  /** The minimum number of nodes in the node pool */
  minReplicas: int32;

  /** The maximum number of nodes in the node pool */
  maxReplicas: int32;
}

/*
* =======================================
* End NodePool resources
* =======================================
*/

/*
* =======================================
*   HyperShift cluster credentials
* =======================================
*/

/** HyperShift cluster credentials */
model HcpOpenShiftClusterCredentials {
  /** kubeadmin user name */
  kubeadminUsername: string;

  /** kube admin password */
  @secret
  kubeadminPassword: string;
}

/** HyperShift cluster admin kubeconfig */
model HcpOpenShiftClusterKubeconfig {
  /** The kubeconfig file */
  @visibility("read")
  @secret
  kubeconfig: string;
}

/*
* =======================================
*   End HyperShift cluster credentials
* =======================================
*/
