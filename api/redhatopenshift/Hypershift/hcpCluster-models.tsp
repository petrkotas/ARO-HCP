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
*   Hypershift cluster core resources
* ===================================
*/

/** Hypershift cluster resource */
model HcpOpenShiftClusterResource is TrackedResource<HcpOpenShiftClusterProperties> {
  /** Name of hypershift cluster */
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
  /** Name of hypershift cluster */
  @pattern("^[a-zA-Z0-9-]{3,24}$")
  @minLength(3)
  @maxLength(24)
  @key("nodePoolName")
  @path
  @segment("nodePools")
  name: string;
}

/** Hypershift cluster properties */
model HcpOpenShiftClusterProperties {
  /** The status of the last operation. */
  @visibility("read")
  provisioningState?: ProvisioningState;

  /** High level cluster configuration */
  @visibility("create", "update")
  clusterProfile: ClusterProfile;

  /** The cluster identity
   * TODO: figure out if needed for workload identity
   */
  @visibility("create", "update")
  identityTbd: string;

  /** Configures the cluster API server profile */
  @visibility("create")
  apiProfile: ApiProfile;

  /** Configures the cluster web console */
  @visibility("create")
  consoleProfile: ConsoleProfile;

  /** Configures the cluster ingresses */
  @visibility("create", "update")
  ingressProfiles: IngressProfile[];

  /** Cluster network configuration */
  @visibility("create")
  networkProfile: NetworkProfile;

  /** Worker node pools configuration, readonly.
   * The NodePool is always created during day-2 operations.
   * Using its separate endpoint.
   */
  @visibility("read")
  nodePoolProfile: NodePoolProfile[];

  /** Enables ETCD encryption, set during creation
   * Allow customer to specify custom encryption keys for etcd
   * if omitted, the default encryption key is used
  */
  @visibility("create")
  etcdEncryption?: EtcdEncryptionProfile;

  /** Specifies whether health checks should be enabled for machines in the NodePool. */
  @visibility("create", "update")
  autoRepair: boolean;

  /** Labels to apply on a created nodes */
  @visibility("create", "update")
  labels: string[];

  /** URl for the OIDC provider */
  @visibility("read")
  oidcIssuerUrl: string;
}

/** The resource provisioning state. */
@lroStatus
enum ProvisioningState {
  ...ResourceProvisioningState,

  /** The resource is being provisioned. */
  Provisioning,

  /** The resource is being updated. */
  Updating,

  /** The resource is being deleted. */
  Deleting,

  /** The resource provisioning request has been accepted. */
  Accepted,
}

/** High level cluster configuration */
model ClusterProfile {
  /** Version of the control plane components */
  controlPlaneVersion: string;

  /** The Azure resourceId for the subnet used by the control plane
   * TODO: Figure out where to place the subnetId
  */
  subnetId: string;
}

/** The visibility of the API server */
enum Visibility {
/** The API server is visible from the internet. */
public: "public",

/** The API server is not visible from the internet. */
private: "private",
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
  visibility: Visibility;
}

/** Configuration of the cluster web console */
model ConsoleProfile {
  /** The cluster web console URL endpoint */
  url: string;
}

/** Configuration of the cluster ingress */
model IngressProfile {
  /** The IP for the ingress */
  ip: string;

  /** The ingress name */
  name: string;

  /** The visibility of the ingress */
  visibility: Visibility;
}

/** Network profile of the cluster */
model NetworkProfile {
  /** The CIDR of the pod IP addresses, for example 10.128.0.0/14 */
  podCidr: string;

  /** The CIDR block for assigned service IPs, for example 172.30.0.0/16 */
  serviceCidr: string;

  /** from which to assign machine IP addresses, for example 10.0.0.0/16 */
  machineCidr: string;

  /** Network host prefix which is defaulted to 23 if not specified. */
  hostPrefix?: int32 = 23;

  /** The core outgoing configuration */
  outboundType: OutboundType;

  /** Specifies whether subnets are pre-attached with an NSG */
  preconfiguredNsgs: PreconfiguredNsgs;
}

/** The outbound routing strategy used to provide your cluster egress to the internet. */
enum OutboundType {
  /** The loadbalancer configuration */
  loadBalancer: "loadBalancer",
}

// TODO: This should be changed to boolean if the strings does not hold names and this struct is used as boolean
/** PreconfiguredNSG represents whether customers want to use their own NSG attached to the subnets */
model PreconfiguredNsgs {
  /** The name of enabled the NSG */
  enabled: string;

  /** The name of the disabled NSG */
  disabled: string;
}

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

  /** The number of worker nodes, it cannot be used together with autoscaling */
  replicas: int32;

  /** The Azure resourceId for the subnet used by the workers */
  subnetId: string;

  /** Whether the worker machines should be encrypted at host */
  encrytptionAtHost: boolean;

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
*   End Hypershift cluster core resources
* =======================================
*/



/*
* =======================================
*   Hypershift cluster credentials
* =======================================
*/

/** Hypershift cluster credentials */
model HcpOpenShiftClusterCredentials {
  /** kubeadmin user name */
  kubeadminUsername: string;

  /** kube admin password */
  @secret
  kubeadminPassword: string;
}

/** Hypershift cluster admin kubeconfig */
model HcpOpenShiftClusterKubeconfig {
  /** The kubeconfig file */
  @visibility("read")
  @secret
  kubeconfig: string;
}

/*
* =======================================
*   End Hypershift cluster credentials
* =======================================
*/




