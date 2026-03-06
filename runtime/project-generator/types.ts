import { TemplateDefinition } from "./templateLoader";

export type ProjectIntent = {
  industry: string;
  objectives: string[];
  targetUsers?: string[];
  constraints?: string[];
  template?: TemplateDefinition;
  raw?: string;
};

export type ArchitecturePlan = {
  services: string[];
  apis: string[];
  dataModels: string[];
  mlModules: string[];
  frontendComponents: string[];
  infrastructure: string[];
  notes?: string;
};

export type StackSelection = {
  backendFramework: string;
  frontendFramework: string;
  database: string;
  messageQueue?: string;
  mlStack?: string;
  infra?: string[];
  reasoning?: string;
};

export type BuildArtifact = {
  path: string;
  description: string;
  files: string[];
};

export type BuilderOutput = {
  artifacts: BuildArtifact[];
  summary: string;
};
