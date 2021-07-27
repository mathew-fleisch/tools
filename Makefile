.PHONY: trigger-asdf-update
trigger-asdf-update:
	scripts/check-environment-variables.sh
	curl -H "Accept: application/vnd.github.everest-preview+json" \
	    -H "Authorization: token $(GIT_TOKEN)" \
	    --request POST \
	    --data '{"event_type": "trigger-asdf-update"}' \
	    https://api.github.com/repos/mathew-fleisch/tools/dispatches