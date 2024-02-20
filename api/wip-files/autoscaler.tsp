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
* =======================================
*   Hypershift cluster autoscaler
* =======================================
*/

/** Hypershift cluster autoscaler */
@parentResource(HcpOpenShiftClusterResource)
model HcpOpenShiftClusterAutoscalerResource is ProxyResource<HcpOpenShiftClusterAutoscalerProperties> {
  /** Name of hypershift cluster */
  @pattern("^[a-zA-Z0-9-]{3,24}$")
  @minLength(3)
  @maxLength(24)
  @key("hypershiftClusterAutoscalerName")
  @path
  @segment("hypershiftClusterAutoscalers")
  name: string;
}

/** Hypershift cluster autoscaler properties */
model HcpOpenShiftClusterAutoscalerProperties {
  /** Provisioning state of the resource */
  @visibility("read")
  provisioningState?: ResourceProvisioningState;

  /** BalanceSimilarNodeGroups enables/disables the --balance-similar-node-groups
   * cluster-autoscaler feature. This feature will automatically identify node groups
   *  with the same instance type and the same set of labels
   * and try to keep the respective sizes of those node groups balanced. */
  balanceSimilarNodeGroups: boolean;

  /** This option specifies labels that cluster autoscaler should ignore
   * when considering node group similarity. For example,
   * if you have nodes with "topology.ebs.csi.aws.com/zone" label,
   * you can add name of this label here to prevent cluster autoscaler
   * from splitting nodes into different node groups based on its value. */
  balancingIgnoredLabels: string[];

  /** Should CA ignore DaemonSet pods when calculating resource utilization
   * for scaling down. false by default. */
  ignoreDaemonsetsUtilization: boolean;

  /** Sets the autoscaler log level. Default value is 1,
   * level 4 is recommended for DEBUGGING and level 6 will enable almost everything. */
  logVerbosity: int32;

  /** Maximum time CA waits for node to be provisioned. */
  maxNodeProvisionTime: string;

  /** Gives pods graceful termination time before scaling down. */
  maxPodGracePeriod: string;

  /** To allow users to schedule "best-effort" pods, which shouldn't trigger Cluster Autoscaler actions,
   * but only run when there are spare resources available,
   * More info: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#how-does-cluster-autoscaler-work-with-pod-priority-and-preemption. */
  podPriorityThreshold: int32;

  /** Autoscaler resource limits */
  resourceLimits: AutoscalerResourceLimits;

  /** Autoscaler scale down configuration */
  scaleDown: AutoscalerScaleDownConfig;

  /** Enables/Disables --skip-nodes-with-local-storage CA feature flag.
   * If true cluster autoscaler will never delete nodes with pods with local storage,
   * e.g. EmptyDir or HostPath. true by default at autoscaler. */
  skipNodesWithLocalStorage: boolean;
}

/** Hypershift cluster autoscaler down config */
model AutoscalerScaleDownConfig {
  /** How long after scale up that scale down evaluation resumes. */
  delayAfterAdd: string;
  /** How long after node deletion that scale down evaluation resumes, defaults to scan-interval. */
  delayAfterDelete: string;
  /** How long after scale down failure that scale down evaluation resumes. */
  delayAfterFailure: string;
  /** Should cluster-autoscaler scale down the cluster. */
  enabled: boolean;
  /** How long a node should be unneeded before it is eligible for scale down. */
  unneededTime: string;
  /** Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down. */
  utilizationThreshold: string;
}


/** Hypershift autoscaler resource limits */
model AutoscalerResourceLimits {
  /** Minimum and maximum number of different GPUs in cluster, in the format <gpu_type>::.
   * Cluster autoscaler will not scale the cluster beyond these numbers.
   * Can be passed multiple times. */
  gpus: AutoscalerResourceLimitsGpuLimit[];

  /** Mininum and maximum number of cores used by the autoscaler. */
  cores: ResourceRange;

  /** Maximum number of nodes in the cluster */
  maxNodesTotal: int32;

  /** Minimum and maxium memory used by the autoscaler */
  memory: ResourceRange;
}

/** Hypershift autoscaler gpu limit configuration */
model AutoscalerResourceLimitsGpuLimit {
  /** The minimum and maximum number of GPUs of a certain type that the cluster can have. */
  range: ResourceRange;

  /** The type of GPU to associate with the minimum and maximum limits.
   * This value is used by the Cluster Autoscaler to identify Nodes
   * that will have GPU capacity by searching for it as a label value on the Node objects.
   * For example, Nodes that carry the label key cluster-api/accelerator with
   * the label value being the same as the Type field will be counted towards the resource limits
   * by the Cluster Autoscaler. */
  type: string;
}

/** Resource range */
model ResourceRange {
  /** The minimum value of the range */
  min: int32;

  /** The maximum value of the range */
  max: int32;
}


/*
* =======================================
*   End Hypershift cluster autoscaler
* =======================================
*/



/** Hypershift cluster autoscaler operations */
@armResourceOperations(HcpOpenShiftClusterAutoscalerResource)
interface Autoscaler {
    get is ArmResourceRead<HcpOpenShiftClusterAutoscalerResource>;
    createOrUpdate is ArmResourceCreateOrReplaceAsync<HcpOpenShiftClusterAutoscalerResource>;
    update is ArmResourcePatchAsync<HcpOpenShiftClusterAutoscalerResource, HcpOpenShiftClusterAutoscalerProperties>;
    delete is ArmResourceDeleteWithoutOkAsync<HcpOpenShiftClusterAutoscalerResource>;
}