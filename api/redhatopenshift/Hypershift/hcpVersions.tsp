import "@typespec/rest";
import "@typespec/http";
import "@azure-tools/typespec-azure-core";
import "@azure-tools/typespec-azure-resource-manager";

using TypeSpec.Rest;
using TypeSpec.Http;
using Azure.Core;
using Azure.ResourceManager;

namespace Microsoft.RedHatOpenshift;

/** HypershiftClusterVersions represents a location based available Hypershift cluster versions */
@locationResource
model HcpOpenShiftClusterVersion is ProxyResource<HcpOpenShiftClusterVersionProperties> {
    /** The name of the resource */
    @segment("hypershiftClusterVersions")
    @key("hypershiftClusterVersionName")
    @visibility("read")
    @path
    name: string;
}

/** HypershiftClusterVersionProperties is the installable cluster version */
model HcpOpenShiftClusterVersionProperties {
    ...DefaultProvisioningStateProperty;

    /** The cluster version */
    @visibility("read")
    clusterVersion: string;
}

@armResourceOperations(HcpOpenShiftClusterVersion)
interface HypershiftClusterVersionOperations {
    list is ArmResourceListByParent<HcpOpenShiftClusterVersion>;
}