import classNames from "classnames";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";

import { HiExternalLink as ExternalLink } from "react-icons/hi";

import SupabaseLogo from "./landing/assets/supabase-logo-icon.svg?url";
import { nbsp } from "./Utils";

import type { Project as ProjectT } from "../types/supabase";
import type { Grafana as GrafanaT } from "../types/z_types";

dayjs.extend(relativeTime);

const SupabaseProject = ({
  project,
  grafana,
}: {
  project: ProjectT;
  grafana: undefined | GrafanaT;
}) => {
  return (
    <div className="text-black dark:text-white bg-dots w-full rounded-2xl">
      <ProjectRow>
        <RowDivHeader className="basis-1/5 md:basis-1/3">
          <span className="text-black dark:text-white font-bold">Database</span>
        </RowDivHeader>
        <div>
          <a
            className="inline-flex items-center gap-1.5 font-medium link link-primary dark:link-secondary"
            href={`https://supabase.com/dashboard/project/${project.id}`}
            title={`Open ${project.name} in Supabase`}
            target="_blank"
          >
            <img src={SupabaseLogo} alt="Supabase logo" width={12} height={12} />
            {project.name}
            <ExternalLink size={18} />
          </a>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowDivHeader className="basis-1/5 md:basis-1/3">
          <span dangerouslySetInnerHTML={{ __html: nbsp("Project ref") }} />
        </RowDivHeader>
        <div>
          <span className="font-medium break-all">{project.id}</span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowDivHeader className="basis-1/5 md:basis-1/3">Version</RowDivHeader>
        <div>
          <span className="font-medium">{project.database?.version}</span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowDivHeader className="basis-1/5 md:basis-1/3">Region</RowDivHeader>
        <div>
          <span className="font-medium">{project.region}</span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowDivHeader className="basis-1/5 md:basis-1/3">Status</RowDivHeader>
        <div>
          <span
            className={classNames("flex gap-2 flex-col md:flex-row", "font-medium", {
              "text-success": project.status === "ACTIVE_HEALTHY",
              "text-warning": project.status === "INACTIVE",
              "text-error": project.status !== "ACTIVE_HEALTHY" && project.status !== "INACTIVE",
            })}
          >
            <span>{project.status}</span>
            <span>
              {project.status === "INACTIVE" && !grafana && (
                <span className="text-zinc-500">
                  You’ll have to{" "}
                  <a
                    className="link link-primary dark:link-secondary"
                    href={`https://supabase.com/dashboard/project/${project.id}`}
                  >
                    restore
                  </a>{" "}
                  this project to provision Supafana
                </span>
              )}
            </span>
          </span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowDivHeader className="basis-1/5 md:basis-1/3">Created</RowDivHeader>
        <div>
          <span className="inline-block font-medium first-letter:capitalize">
            {dayjs(project.created_at).fromNow()}
          </span>
        </div>
      </ProjectRow>
    </div>
  );
};

const ProjectRow = ({ children }: { children: JSX.Element[] }) => {
  return (
    <div className="flex flex-col md:flex-row px-4 py-3 border-b border-zinc-500 last-of-type:border-none text-sm">
      {children}
    </div>
  );
};

const RowDivHeader = ({
  children,
  className,
}: {
  children: JSX.Element | string;
  className?: string;
}) => {
  return (
    <div className={classNames(className)}>
      <span className="text-gray-500 dark:text-gray-300">{children}</span>
    </div>
  );
};

export default SupabaseProject;

