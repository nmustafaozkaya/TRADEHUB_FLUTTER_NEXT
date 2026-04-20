import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  webpack: (config, { isServer }) => {
    // Prevent webpack from trying to parse the native `.node` binary from msnodesqlv8.
    if (isServer) {
      config.externals = config.externals || [];
      config.externals.push("msnodesqlv8");
    }
    return config;
  },
};

export default nextConfig;
