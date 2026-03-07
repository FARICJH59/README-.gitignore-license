import { Agent, callable } from "agents";

type ApprovalState = {
  draftId?: string;
  reviewer?: string;
  status?: "pending" | "approved" | "rejected";
  notes?: string;
};

export class ContentApprovalAgent extends Agent {
  initialState: ApprovalState = { status: "pending" };

  @callable()
  requestApproval(draftId: string, reviewer: string) {
    this.setState({ draftId, reviewer, status: "pending" });
    return this.state;
  }

  @callable()
  approve(notes?: string) {
    this.setState({ ...this.state, status: "approved", notes });
    return this.state;
  }

  @callable()
  reject(notes?: string) {
    this.setState({ ...this.state, status: "rejected", notes });
    return this.state;
  }
}
