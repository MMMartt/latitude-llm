import { DocumentVersion, Project } from '$core/browser'
import {
  CommitStatus,
  HEAD_COMMIT,
  ModifiedDocumentType,
} from '$core/constants'
import { NotFoundError, Result } from '$core/lib'
import { commits, projects } from '$core/schema'
import { recomputeChanges, RecomputedChanges } from '$core/services'
import { assertCommitIsDraft } from '$core/services/documents/utils'
import {
  and,
  desc,
  eq,
  getTableColumns,
  isNotNull,
  isNull,
  or,
} from 'drizzle-orm'

import Repository, { PaginationArgs } from '../repository'

const byErrors =
  (c: RecomputedChanges) => (a: DocumentVersion, b: DocumentVersion) => {
    const aErrors = c.errors[a.documentUuid]?.length ?? 0
    const bErrors = c.errors[b.documentUuid]?.length ?? 0
    return bErrors - aErrors
  }

export type ChangedDocument = {
  documentUuid: string
  path: string
  errors: number
  changeType: ModifiedDocumentType
}
function filterByStatusQuery({
  scope,
  status,
}: {
  status: CommitStatus
  scope: typeof CommitsRepository.prototype.scope
}) {
  switch (status) {
    case CommitStatus.Draft:
      return isNull(scope.mergedAt)
    case CommitStatus.Merged:
      return isNotNull(scope.mergedAt)
    default:
      return or(isNotNull(scope.mergedAt), isNull(scope.mergedAt))
  }
}

export class CommitsRepository extends Repository {
  get scope() {
    return this.db
      .select(getTableColumns(commits))
      .from(commits)
      .innerJoin(projects, eq(projects.workspaceId, this.workspaceId))
      .where(eq(commits.projectId, projects.id))
      .as('commitsScope')
  }

  async getHeadCommit(project: Project) {
    const result = await this.db
      .select()
      .from(this.scope)
      .where(
        and(
          isNotNull(this.scope.mergedAt),
          eq(this.scope.projectId, project.id),
        ),
      )
      .orderBy(desc(this.scope.mergedAt))
      .limit(1)

    if (result.length < 1) {
      return Result.error(new NotFoundError('No head commit found'))
    }

    return Result.ok(result[0]!)
  }

  async getCommitByUuid({
    uuid,
    project,
  }: {
    project?: Project
    uuid: string
  }) {
    if (uuid === HEAD_COMMIT) {
      if (!project) {
        return Result.error(new NotFoundError('Project ID is required'))
      }

      return this.getHeadCommit(project)
    }

    const result = await this.db
      .select()
      .from(this.scope)
      .where(eq(this.scope.uuid, uuid))
      .limit(1)
    const commit = result[0]
    if (!commit) return Result.error(new NotFoundError('Commit not found'))

    return Result.ok(commit)
  }

  async getCommitById(id: number) {
    const result = await this.db
      .select()
      .from(this.scope)
      .where(eq(this.scope.id, id))
      .limit(1)
    const commit = result[0]
    if (!commit) return Result.error(new NotFoundError('Commit not found'))

    return Result.ok(commit)
  }

  async getCommits() {
    return this.db.select().from(this.scope)
  }

  async getFirstCommitForProject(project: Project) {
    const result = await this.db
      .select()
      .from(this.scope)
      .where(eq(this.scope.projectId, project.id))
      .orderBy(this.scope.createdAt)
      .limit(1)

    if (result.length < 1) {
      return Result.error(new NotFoundError('No commits found'))
    }

    return Result.ok(result[0]!)
  }

  async getCommitsByProject({
    project,
    page = 1,
    filterByStatus = CommitStatus.All,
    pageSize = 20,
  }: { project: Project; filterByStatus?: CommitStatus } & PaginationArgs) {
    const filter = filterByStatusQuery({
      scope: this.scope,
      status: filterByStatus,
    })
    const query = this.db
      .select({
        id: this.scope.id,
        uuid: this.scope.uuid,
        title: this.scope.title,
        version: this.scope.version,
        description: this.scope.description,
        projectId: this.scope.projectId,
        userId: this.scope.userId,
        mergedAt: this.scope.mergedAt,
        createdAt: this.scope.createdAt,
        updatedAt: this.scope.updatedAt,
      })
      .from(this.scope)
      .where(and(eq(this.scope.projectId, project.id), filter))
      .orderBy(desc(this.scope.createdAt))

    const result = await Repository.paginateQuery({
      query: query.$dynamic(),
      page,
      pageSize,
    })
    return Result.ok(result)
  }

  async getChanges(id: number) {
    const commitResult = await this.getCommitById(id)
    if (commitResult.error) return commitResult

    const commit = commitResult.value
    const isDraft = assertCommitIsDraft(commit)
    if (isDraft.error) return isDraft

    const result = await recomputeChanges(commit)
    if (result.error) return result

    const changes = result.value
    const head = changes.headDocuments.reduce(
      (acc, doc) => {
        acc[doc.documentUuid] = doc
        return acc
      },
      {} as Record<string, DocumentVersion>,
    )

    return Result.ok(
      changes.changedDocuments.sort(byErrors(changes)).map((changedDoc) => {
        const changeType = head[changedDoc.documentUuid]
          ? changedDoc.deletedAt
            ? ModifiedDocumentType.Deleted
            : ModifiedDocumentType.Updated
          : ModifiedDocumentType.Created

        return {
          documentUuid: changedDoc.documentUuid,
          path: changedDoc.path,
          errors: changes.errors[changedDoc.documentUuid]?.length ?? 0,
          changeType,
        }
      }),
    )
  }
}