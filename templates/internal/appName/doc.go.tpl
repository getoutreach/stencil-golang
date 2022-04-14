// Copyright {{ .currentYear }} Outreach Corporation. All Rights Reserved.

// Description: This file contains the package documentation for {{ .appName }}.

// Package {{ .underscoreAppName }} contains the base service activities such
// as HTTP, gRPC, temporal, Kafka consumers, etc. as well as foundational
// functionality such as loading configuration.
package {{ .underscoreAppName }} //nolint:revive // Why: This nolint is here just in case your project name contains any of [-_].
