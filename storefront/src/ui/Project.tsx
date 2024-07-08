import React from "react";
import classNames from "classnames";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";

import SupabaseLogo from "./landing/assets/supabase-logo-icon.svg?url";

import type { Project as ProjectT } from "../types/supabase";

dayjs.extend(relativeTime);

type ProvisioningStatus = "initial" | "provisioning" | "provisioned" | "error";

const Project = ({ project }: { project: ProjectT }) => {
  const [provisioningStatus, setProvisioningStatus] = React.useState<ProvisioningStatus>("initial");

  React.useEffect(() => {
    if (provisioningStatus === "provisioning") {
      setTimeout(() => {
        setProvisioningStatus("provisioned");
      }, 5000);
    }
  }, [provisioningStatus]);

  return (
    <div className="p-4 border border-gray-200 dark:border-gray-700 rounded-md flex gap-4">
      <table className="text-gray-200 dark:text-gray-700 bg-dots table max-w-1/2">
        <tbody className="text-black dark:text-white">
          <tr>
            <RowHeader>Database</RowHeader>
            <td>
              <a
                className="inline-flex items-baseline gap-1.5 font-medium link link-primary dark:link-secondary"
                href={`https://supabase.com/dashboard/project/${project.id}`}
                title={`Open ${project.name} in Supabase`}
              >
                <img src={SupabaseLogo} alt="Supabase logo" width={12} height={12} />
                {project.name}
              </a>
            </td>
          </tr>
          <tr>
            <RowHeader>Project&nbsp;ref</RowHeader>
            <td>
              <span className="font-medium">{project.id}</span>
            </td>
          </tr>
          <tr>
            <RowHeader>Version</RowHeader>
            <td>
              <span className="font-medium">{project.database?.version}</span>
            </td>
          </tr>
          <tr>
            <RowHeader>Region</RowHeader>
            <td>
              <span className="font-medium">{project.region}</span>
            </td>
          </tr>
          <tr>
            <RowHeader>Status</RowHeader>
            <td>
              <span
                className={classNames(
                  "font-medium",
                  (() => {
                    if (project.status === "ACTIVE_HEALTHY") {
                      return "text-success";
                    } else if (project.status === "INACTIVE") {
                      return "text-warning";
                    } else {
                      return "text-error";
                    }
                  })()
                )}
              >
                {project.status}
              </span>
            </td>
          </tr>
          <tr>
            <RowHeader>Created</RowHeader>
            <td>
              <span className="font-medium">{dayjs(project.created_at).fromNow()}</span>
            </td>
          </tr>
        </tbody>
      </table>
      <div className="min-h-full w-full flex items-center justify-center">
        {provisioningStatus === "initial" && (
          <button className="btn" onClick={() => setProvisioningStatus("provisioning")}>
            Provision observability dashboard
          </button>
        )}
        {provisioningStatus === "provisioning" && (
          <div className="flex gap-1">
            <span>Provisioning in progress</span>
            <span className="text-gray-700 dark:text-gray-300 self-end loading loading-dots loading-xs"></span>
          </div>
        )}
        {provisioningStatus === "provisioned" && (
          <div className="flex flex-col items-center">
            <a
              href={`https://supafana.com/dashboard/${project.id}`}
              target="_blank"
              className="break-all font-medium text-sm link link-primary dark:link-secondary"
            >
              https://supafana.com/dashboard/{project.id}
            </a>
          </div>
        )}
      </div>
    </div>
  );
};

const RowHeader = ({ children }: { children: JSX.Element | string }) => {
  return (
    <td>
      <span className="text-gray-500 dark:text-gray-300">{children}</span>
    </td>
  );
};

export default Project;
